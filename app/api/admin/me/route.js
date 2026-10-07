import {userFromRequest} from '../../billing/_server';

export const dynamic='force-dynamic';

function err(e){
  return Response.json(
    {error:e?.message||'Erro interno.',code:e?.code||'ADMIN_ME_ERROR'},
    {status:e?.status||500}
  );
}

export async function GET(req){
  try{
    const {user,db}=await userFromRequest(req);
    const {data:adminRow,error}=await db
      .from('saas_admins')
      .select('user_id,nome,ativo')
      .eq('user_id',user.id)
      .eq('ativo',true)
      .maybeSingle();

    if(error){
      throw Object.assign(
        new Error(`Falha ao validar administrador SaaS: ${error.message}`),
        {status:500,code:'ADMIN_QUERY_FAILED'}
      );
    }

    return Response.json({
      isAdmin:!!adminRow,
      admin:adminRow?{user_id:user.id,email:user.email,nome:adminRow.nome||user.email}:null
    });
  }catch(e){return err(e)}
}
