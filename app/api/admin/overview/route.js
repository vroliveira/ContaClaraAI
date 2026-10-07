import {userFromRequest} from '../../billing/_server';

export const dynamic='force-dynamic';

function err(e){return Response.json({error:e?.message||'Erro interno.',code:e?.code||'ADMIN_ERROR'},{status:e?.status||500})}

export async function GET(req){
 try{
  const {user,db}=await userFromRequest(req);
  const {data:adminRow,error:adminError}=await db.from('saas_admins').select('user_id,nome,ativo').eq('user_id',user.id).eq('ativo',true).maybeSingle();
  if(adminError)throw Object.assign(new Error(`Falha ao validar administrador SaaS: ${adminError.message}`),{status:500,code:'ADMIN_QUERY_FAILED'});
  if(!adminRow)throw Object.assign(new Error('Acesso restrito à administração do ContaClaraAI.'),{status:403,code:'ADMIN_FORBIDDEN'});

  const [{data:orgs,error:oe},{data:plans,error:pe},{data:subs,error:se},{data:ai,error:ae},{data:storage,error:ste},{data:members,error:me},{data:controls,error:ce}]=await Promise.all([
   db.from('organizacoes').select('id,nome,email,owner_id,ativo,created_at').order('created_at',{ascending:false}),
   db.from('planos_saas').select('*').order('preco_mensal'),
   db.from('assinaturas').select('*,planos_saas(id,codigo,nome,preco_mensal)').order('updated_at',{ascending:false}),
   db.from('consumo_ia').select('organizacao_id,competencia,quantidade').order('competencia',{ascending:false}),
   db.from('consumo_armazenamento').select('organizacao_id,bytes_utilizados,arquivos,updated_at'),
   db.from('organizacao_membros').select('organizacao_id,status'),
   db.from('controles').select('organizacao_id,ativo')
  ]);
  const firstError=oe||pe||se||ae||ste||me||ce;if(firstError)throw Object.assign(new Error(firstError.message),{status:500,code:'ADMIN_DATA_FAILED'});
  const {data:usersData,error:usersError}=await db.auth.admin.listUsers({page:1,perPage:1000});
  if(usersError)throw Object.assign(new Error(`Falha ao consultar clientes: ${usersError.message}`),{status:500,code:'ADMIN_USERS_FAILED'});
  const users=(usersData?.users||[]).map(u=>({id:u.id,email:u.email||'',created_at:u.created_at,last_sign_in_at:u.last_sign_in_at||null}));
  const currentMonth=new Date().toISOString().slice(0,7)+'-01';
  const active=(subs||[]).filter(s=>s.status==='ativo');
  const mrr=active.reduce((n,s)=>n+Number(s.valor??s.planos_saas?.preco_mensal??0),0);
  const trial=(subs||[]).filter(s=>s.status==='trial').length;
  const overdue=(subs||[]).filter(s=>s.status==='inadimplente').length;
  const aiMonth=(ai||[]).filter(x=>String(x.competencia).slice(0,7)===currentMonth.slice(0,7)).reduce((n,x)=>n+Number(x.quantidade||0),0);
  const storageBytes=(storage||[]).reduce((n,x)=>n+Number(x.bytes_utilizados||0),0);
  return Response.json({admin:{user_id:user.id,email:user.email,nome:adminRow.nome||user.email},generated_at:new Date().toISOString(),kpis:{clientes:users.length,workspaces:(orgs||[]).length,assinaturas_ativas:active.length,trials:trial,inadimplentes:overdue,mrr,arr:mrr*12,ia_mes:aiMonth,storage_bytes:storageBytes},users,organizations:orgs||[],plans:plans||[],subscriptions:subs||[],ai:ai||[],storage:storage||[],members:members||[],controls:controls||[]});
 }catch(e){return err(e)}
}
