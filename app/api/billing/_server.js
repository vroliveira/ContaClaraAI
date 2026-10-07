import {createClient} from '@supabase/supabase-js';

export const mpBase='https://api.mercadopago.com';

function httpError(message,status=400,code='BILLING_ERROR'){
  const e=new Error(message);e.status=status;e.code=code;return e;
}

function env(name){return String(process.env[name]||'').trim()}

export function admin(){
  const url=env('NEXT_PUBLIC_SUPABASE_URL');
  const key=env('SUPABASE_SERVICE_ROLE_KEY');
  if(!url||!key)throw httpError('Supabase server-side não configurado. Verifique NEXT_PUBLIC_SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY.',500,'SUPABASE_SERVER_CONFIG');
  return createClient(url,key,{auth:{persistSession:false,autoRefreshToken:false}});
}

export async function userFromRequest(req){
  const h=req.headers.get('authorization')||'';
  const token=h.startsWith('Bearer ')?h.slice(7).trim():'';
  if(!token)throw httpError('Não autenticado. Entre novamente.',401,'AUTH_MISSING');
  const url=env('NEXT_PUBLIC_SUPABASE_URL');
  const publishable=env('NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY');
  if(!url||!publishable)throw httpError('Supabase Auth server-side não configurado.',500,'SUPABASE_AUTH_CONFIG');
  const authClient=createClient(url,publishable,{auth:{persistSession:false,autoRefreshToken:false},global:{headers:{Authorization:`Bearer ${token}`}}});
  const {data,error}=await authClient.auth.getUser(token);
  if(error||!data?.user)throw httpError(`Sessão inválida ou expirada${error?.message?`: ${error.message}`:''}. Entre novamente.`,401,'AUTH_INVALID');
  return {user:data.user,db:admin()};
}

export async function assertOrgAdmin(db,userId,organizationId){
  const orgId=String(organizationId||'').trim();
  if(!orgId)throw httpError('O workspace não foi informado pelo navegador.',400,'ORG_ID_MISSING');

  const {data:org,error:orgError}=await db
    .from('organizacoes')
    .select('id,owner_id,nome')
    .eq('id',orgId)
    .maybeSingle();

  if(orgError){
    // Não expõe URL, chaves ou detalhes sensíveis, mas preserva a mensagem do PostgREST.
    throw httpError(`Não foi possível consultar a organização no Supabase: ${orgError.message}`,500,'ORG_QUERY_FAILED');
  }
  if(!org)throw httpError(`A organização selecionada (${orgId}) não foi encontrada no Supabase configurado na Vercel. Verifique se NEXT_PUBLIC_SUPABASE_URL e SUPABASE_SERVICE_ROLE_KEY pertencem ao mesmo projeto.`,404,'ORG_NOT_FOUND');
  if(org.owner_id===userId)return org;

  const {data:m,error:memberError}=await db
    .from('organizacao_membros')
    .select('papel,status,user_id')
    .eq('organizacao_id',orgId)
    .eq('user_id',userId)
    .maybeSingle();

  if(memberError)throw httpError(`Não foi possível validar seu acesso à organização: ${memberError.message}`,500,'ORG_MEMBER_QUERY_FAILED');
  if(!m||m.status!=='ativo'||m.papel!=='administrador')throw httpError('Somente o proprietário ou um administrador ativo pode gerenciar a assinatura.',403,'ORG_FORBIDDEN');
  return org;
}

export async function mp(path,options={}){
  const token=env('MERCADOPAGO_ACCESS_TOKEN');
  if(!token)throw httpError('MERCADOPAGO_ACCESS_TOKEN não configurado.',500,'MP_TOKEN_MISSING');
  const r=await fetch(mpBase+path,{...options,headers:{Authorization:`Bearer ${token}`,'Content-Type':'application/json',...(options.headers||{})},cache:'no-store'});
  const text=await r.text();let data={};try{data=text?JSON.parse(text):{}}catch{data={message:text}}
  if(!r.ok)throw httpError(data.message||data.error||`Mercado Pago HTTP ${r.status}`,r.status>=500?502:400,'MP_API_ERROR');
  return data;
}

export function mapStatus(s){if(s==='authorized')return 'ativo';if(s==='paused'||s==='pending')return 'inadimplente';if(s==='cancelled'||s==='canceled')return 'cancelado';return 'inadimplente'}

export async function persistSubscription(db,organizationId,sub){
  const planExternal=sub.preapproval_plan_id||null;let planCode=null;
  if(planExternal===env('MERCADOPAGO_PLUS_PLAN_ID'))planCode='plus';
  if(planExternal===env('MERCADOPAGO_PRO_PLAN_ID'))planCode='pro';
  if(!planCode)return;
  const {data:p,error:planError}=await db.from('planos_saas').select('id').eq('codigo',planCode).maybeSingle();
  if(planError)throw httpError(`Erro ao localizar o plano ${planCode}: ${planError.message}`,500,'PLAN_QUERY_FAILED');
  if(!p)throw httpError(`Plano interno ${planCode} não encontrado.`,500,'PLAN_NOT_FOUND');
  const {error:updateError}=await db.from('assinaturas').update({plano_id:p.id,status:mapStatus(sub.status),provedor:'mercado_pago',assinatura_externa_id:sub.id,plano_externo_id:planExternal,pagador_email:sub.payer_email||null,valor:Number(sub.auto_recurring?.transaction_amount||0)||null,proxima_cobranca:sub.next_payment_date||null,periodo_inicio:sub.auto_recurring?.start_date||null,periodo_fim:sub.auto_recurring?.end_date||null,data_cancelamento:['cancelled','canceled'].includes(sub.status)?new Date().toISOString():null,updated_at:new Date().toISOString()}).eq('organizacao_id',organizationId);
  if(updateError)throw httpError(`Erro ao atualizar a assinatura: ${updateError.message}`,500,'SUBSCRIPTION_UPDATE_FAILED');
}
