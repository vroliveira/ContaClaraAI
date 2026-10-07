import {NextResponse} from 'next/server';
export const runtime='nodejs'; export const maxDuration=30;
function extractJson(text){const clean=String(text||'').trim().replace(/^```json\s*/i,'').replace(/```$/,'').trim();const a=clean.indexOf('{'),b=clean.lastIndexOf('}');if(a<0||b<a)throw new Error('A IA não retornou JSON válido.');return JSON.parse(clean.slice(a,b+1))}
export async function POST(request){try{
 if(!process.env.OPENAI_API_KEY)return NextResponse.json({error:'OPENAI_API_KEY não configurada.'},{status:503});
 const auth=request.headers.get('authorization')||'';if(!auth.startsWith('Bearer '))return NextResponse.json({error:'Não autorizado.'},{status:401});
 const url=process.env.NEXT_PUBLIC_SUPABASE_URL,key=process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;if(!url||!key)return NextResponse.json({error:'Configuração do Supabase ausente.'},{status:500});
 const check=await fetch(`${url}/auth/v1/user`,{headers:{Authorization:auth,apikey:key},cache:'no-store'});if(!check.ok)return NextResponse.json({error:'Sessão inválida.'},{status:401});
 const body=await request.json();const transaction=body.transaction||{},candidates=Array.isArray(body.candidates)?body.candidates.slice(0,20):[],categories=Array.isArray(body.categories)?body.categories:[];
 const instruction=`Você faz conciliação bancária no ContaClaraAI. Compare UMA movimentação bancária com despesas candidatas. Priorize igualdade de valor absoluto, proximidade de data, favorecido/descrição e referências textuais. Não invente correspondência. Se não houver evidência suficiente, despesa_id deve ser null. Sugira também uma categoria somente entre as fornecidas. Retorne SOMENTE JSON válido: {"despesa_id":string|null,"confianca":integer 0-100,"categoria":string|null,"justificativa":string}. Movimentação: ${JSON.stringify(transaction)}. Candidatas: ${JSON.stringify(candidates)}. Categorias: ${JSON.stringify(categories)}`;
 const ai=await fetch('https://api.openai.com/v1/responses',{method:'POST',headers:{Authorization:`Bearer ${process.env.OPENAI_API_KEY}`,'Content-Type':'application/json'},body:JSON.stringify({model:process.env.OPENAI_MODEL||'gpt-5.6-luna',input:instruction,reasoning:{effort:'low'},max_output_tokens:500})});
 const payload=await ai.json();if(!ai.ok)return NextResponse.json({error:payload?.error?.message||'Falha no provedor de IA.'},{status:502});
 const text=(payload.output||[]).flatMap(o=>o.content||[]).filter(x=>x.type==='output_text').map(x=>x.text).join('\n');return NextResponse.json({data:extractJson(text)});
 }catch(e){return NextResponse.json({error:e?.message||'Erro inesperado na conciliação.'},{status:500})}}
