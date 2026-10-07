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

    // v0.12.2: não criamos /preapproval sem card_token_id. Para planos associados,
    // usamos o checkout hospedado pelo Mercado Pago retornado em init_point.
    const plan=await mp(`/preapproval_plan/${encodeURIComponent(planId)}`,{method:'GET'});
    if(plan.status!=='active')throw Object.assign(new Error('O plano selecionado não está ativo no Mercado Pago.'),{status:400,code:'MP_PLAN_INACTIVE'});
    if(!plan.init_point)throw Object.assign(new Error('O Mercado Pago não retornou a URL de checkout do plano.'),{status:502,code:'MP_INIT_POINT_MISSING'});

    const email=String(payerEmail||user.email||'').trim().toLowerCase();
    if(!email)throw Object.assign(new Error('E-mail do pagador não encontrado.'),{status:400,code:'PAYER_EMAIL_MISSING'});

    // Guarda o vínculo antes do redirecionamento. O checkout hospedado cria a
    // assinatura no Mercado Pago; o webhook usa este registro para relacionar
    // a assinatura ao workspace sem confiar em parâmetros do navegador.
    const {error:pendingError}=await db.from('billing_checkout_pendentes').upsert({
      organizacao_id:org.id,
      user_id:user.id,
      plano_codigo:planCode,
      plano_externo_id:planId,
      pagador_email:email,
      status:'pendente',
      updated_at:new Date().toISOString()
    },{onConflict:'organizacao_id'});
    if(pendingError)throw Object.assign(new Error(`Não foi possível preparar o checkout: ${pendingError.message}`),{status:500,code:'CHECKOUT_PENDING_FAILED'});

    return NextResponse.json({checkoutUrl:plan.init_point,hosted:true});
  }catch(e){
    return NextResponse.json({error:e.message||'Falha no checkout.',code:e.code||'CHECKOUT_ERROR'},{status:e.status||400});
  }
}
