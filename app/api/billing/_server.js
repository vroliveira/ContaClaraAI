import {createClient} from '@supabase/supabase-js';
export const mpBase='https://api.mercadopago.com';
export function admin(){const url=process.env.NEXT_PUBLIC_SUPABASE_URL;const key=process.env.SUPABASE_SERVICE_ROLE_KEY;if(!url||!key)throw new Error('Supabase server-side não configurado.');return createClient(url,key,{auth:{persistSession:false,autoRefreshToken:false}})}
export async function userFromRequest(req){
  const h=req.headers.get('authorization')||'';
  const token=h.startsWith('Bearer ')?h.slice(7).trim():'';
  if(!token){const e=new Error('Não autenticado. Entre novamente.');e.status=401;throw e}
  const url=process.env.NEXT_PUBLIC_SUPABASE_URL;
  const publishable=process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;
  if(!url||!publishable)throw new Error('Supabase Auth server-side não configurado.');
  // Valida o JWT com o mesmo projeto/chave pública usado pelo navegador.
  const authClient=createClient(url,publishable,{auth:{persistSession:false,autoRefreshToken:false},global:{headers:{Authorization:`Bearer ${token}`}}});
  const {data,error}=await authClient.auth.getUser(token);
  if(error||!data?.user){const e=new Error(`Sessão inválida ou expirada${error?.message?`: ${error.message}`:''}. Entre novamente.`);e.status=401;throw e}
  return {user:data.user,db:admin()}
}
export async function assertOrgAdmin(db,userId,organizationId){const {data:org}=await db.from('organizacoes').select('id,owner_id').eq('id',organizationId).single();if(!org)throw new Error('Organização não encontrada.');if(org.owner_id===userId)return org;const {data:m}=await db.from('organizacao_membros').select('papel,status').eq('organizacao_id',organizationId).eq('user_id',userId).maybeSingle();if(!m||m.status!=='ativo'||m.papel!=='administrador')throw new Error('Somente proprietário ou administrador pode gerenciar a assinatura.');return org}
export async function mp(path,options={}){const token=process.env.MERCADOPAGO_ACCESS_TOKEN;if(!token)throw new Error('MERCADOPAGO_ACCESS_TOKEN não configurado.');const r=await fetch(mpBase+path,{...options,headers:{Authorization:`Bearer ${token}`,'Content-Type':'application/json',...(options.headers||{})},cache:'no-store'});const text=await r.text();let data={};try{data=text?JSON.parse(text):{}}catch{data={message:text}}if(!r.ok)throw new Error(data.message||data.error||`Mercado Pago HTTP ${r.status}`);return data}
export function mapStatus(s){if(s==='authorized')return 'ativo';if(s==='paused'||s==='pending')return 'inadimplente';if(s==='cancelled'||s==='canceled')return 'cancelado';return 'inadimplente'}
export async function persistSubscription(db,organizationId,sub){const planExternal=sub.preapproval_plan_id||null;let planCode=null;if(planExternal===process.env.MERCADOPAGO_PLUS_PLAN_ID)planCode='plus';if(planExternal===process.env.MERCADOPAGO_PRO_PLAN_ID)planCode='pro';if(!planCode)return;const {data:p}=await db.from('planos_saas').select('id').eq('codigo',planCode).single();if(!p)return;await db.from('assinaturas').update({plano_id:p.id,status:mapStatus(sub.status),provedor:'mercado_pago',assinatura_externa_id:sub.id,plano_externo_id:planExternal,pagador_email:sub.payer_email||null,valor:Number(sub.auto_recurring?.transaction_amount||0)||null,proxima_cobranca:sub.next_payment_date||null,periodo_inicio:sub.auto_recurring?.start_date||null,periodo_fim:sub.auto_recurring?.end_date||null,data_cancelamento:['cancelled','canceled'].includes(sub.status)?new Date().toISOString():null,updated_at:new Date().toISOString()}).eq('organizacao_id',organizationId)}
