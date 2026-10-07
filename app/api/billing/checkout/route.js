import {NextResponse} from 'next/server';
import {userFromRequest,assertOrgAdmin,mp} from '../_server';

export async function POST(req){
  try{
    const {organizationId,planCode,payerEmail}=await req.json();
    if(!['plus','pro'].includes(planCode))return NextResponse.json({error:'Plano inválido.',code:'PLAN_INVALID'},{status:400});
    const {user,db}=await userFromRequest(req);
    const org=await assertOrgAdmin(db,user.id,organizationId);
    const planId=planCode==='plus'?String(process.env.MERCADOPAGO_PLUS_PLAN_ID||'').trim():String(process.env.MERCADOPAGO_PRO_PLAN_ID||'').trim();
    if(!planId)throw Object.assign(new Error(`ID do plano ${planCode.toUpperCase()} não configurado.`),{status:500,code:'MP_PLAN_ID_MISSING'});
    const back=String(process.env.NEXT_PUBLIC_APP_URL||new URL(req.url).origin).replace(/\/$/,'');
    const sub=await mp('/preapproval',{method:'POST',body:JSON.stringify({preapproval_plan_id:planId,reason:`ContaClaraAI ${planCode==='plus'?'Plus':'Pro'}`,external_reference:org.id,payer_email:payerEmail||user.email,back_url:`${back}/?billing=return`,notification_url:`${back}/api/billing/webhook`})});
    const {error:updateError}=await db.from('assinaturas').update({provedor:'mercado_pago',assinatura_externa_id:sub.id,plano_externo_id:planId,pagador_email:payerEmail||user.email,status:'inadimplente',updated_at:new Date().toISOString()}).eq('organizacao_id',org.id);
    if(updateError)throw Object.assign(new Error(`Assinatura criada no Mercado Pago, mas não foi possível atualizar o Supabase: ${updateError.message}`),{status:500,code:'SUBSCRIPTION_UPDATE_FAILED'});
    return NextResponse.json({checkoutUrl:sub.init_point,id:sub.id});
  }catch(e){
    return NextResponse.json({error:e.message||'Falha no checkout.',code:e.code||'CHECKOUT_ERROR'},{status:e.status||400});
  }
}
