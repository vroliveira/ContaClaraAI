import {NextResponse} from 'next/server';

export const runtime='nodejs';
export const maxDuration=60;

function dataUrl(buffer,mime){return `data:${mime};base64,${buffer.toString('base64')}`}
function extractJson(text){const clean=String(text||'').trim().replace(/^```json\s*/i,'').replace(/```$/,'').trim();const a=clean.indexOf('{'),b=clean.lastIndexOf('}');if(a<0||b<a)throw new Error('A IA não retornou JSON válido.');return JSON.parse(clean.slice(a,b+1))}

export async function POST(request){
 try{
  if(!process.env.OPENAI_API_KEY)return NextResponse.json({error:'OPENAI_API_KEY não configurada na Vercel.'},{status:503});
  const auth=request.headers.get('authorization')||'';
  if(!auth.startsWith('Bearer '))return NextResponse.json({error:'Não autorizado.'},{status:401});
  const supabaseUrl=process.env.NEXT_PUBLIC_SUPABASE_URL;
  const supabaseKey=process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;
  if(!supabaseUrl||!supabaseKey)return NextResponse.json({error:'Configuração do Supabase ausente.'},{status:500});
  const check=await fetch(`${supabaseUrl}/auth/v1/user`,{headers:{Authorization:auth,apikey:supabaseKey},cache:'no-store'});
  if(!check.ok)return NextResponse.json({error:'Sessão inválida.'},{status:401});

  const form=await request.formData(); const file=form.get('file'); const context=String(form.get('context')||'');
  let categories=[];try{categories=JSON.parse(String(form.get('categories')||'[]'))}catch{}
  if(!file||typeof file.arrayBuffer!=='function')return NextResponse.json({error:'Comprovante não enviado.'},{status:400});
  if(file.size>10*1024*1024)return NextResponse.json({error:'Arquivo maior que 10 MB.'},{status:413});
  const allowed=['application/pdf','image/jpeg','image/png','image/webp'];
  if(file.type&&!allowed.includes(file.type))return NextResponse.json({error:'Use PDF, JPG, PNG ou WEBP.'},{status:415});
  const buffer=Buffer.from(await file.arrayBuffer());
  const instruction=`Você extrai dados financeiros de comprovantes brasileiros para o ContaClaraAI. Use o documento como fonte principal e a conversa apenas como contexto. Nunca invente dados. Retorne SOMENTE JSON válido com: descricao (string|null), categoria (uma das categorias fornecidas ou null), valor (number|null), data (YYYY-MM-DD|null), pagador (string|null), recebedor (string|null), forma_pagamento (PIX|Cartão|Dinheiro|Transferência|null), pix_transacao_id (string|null), confianca (inteiro 0-100), alertas (array de strings). Categorias: ${JSON.stringify(categories)}. Contexto WhatsApp: ${context.slice(0,2500)}`;
  const content=[{type:'input_text',text:instruction}];
  if(file.type==='application/pdf')content.push({type:'input_file',filename:file.name||'comprovante.pdf',file_data:dataUrl(buffer,'application/pdf')});
  else content.push({type:'input_image',image_url:dataUrl(buffer,file.type||'image/jpeg'),detail:'high'});
  const ai=await fetch('https://api.openai.com/v1/responses',{method:'POST',headers:{Authorization:`Bearer ${process.env.OPENAI_API_KEY}`,'Content-Type':'application/json'},body:JSON.stringify({model:process.env.OPENAI_MODEL||'gpt-5.6-luna',input:[{role:'user',content}],reasoning:{effort:'low'},max_output_tokens:1200})});
  const payload=await ai.json();if(!ai.ok)return NextResponse.json({error:payload?.error?.message||'Falha no provedor de IA.'},{status:502});
  const text=(payload.output||[]).flatMap(o=>o.content||[]).filter(x=>x.type==='output_text').map(x=>x.text).join('\n');
  const data=extractJson(text);return NextResponse.json({data});
 }catch(e){return NextResponse.json({error:e?.message||'Erro inesperado na análise.'},{status:500})}
}
