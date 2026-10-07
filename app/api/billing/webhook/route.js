import {NextResponse} from 'next/server';
import {admin,mp,persistSubscription,subscriptionPayerEmail} from '../_server';

function notificationData(reqUrl, body) {
  const url = new URL(reqUrl);
  const dataId = url.searchParams.get('data.id') || url.searchParams.get('data_id') || body?.data?.id || body?.id || null;
  const type = url.searchParams.get('type') || body?.type || body?.topic || null;
  return {dataId: dataId ? String(dataId) : null, type};
}

function knownPlanCode(subscription) {
  const planId=String(subscription?.preapproval_plan_id||'');
  if(planId===String(process.env.MERCADOPAGO_PLUS_PLAN_ID||''))return 'plus';
  if(planId===String(process.env.MERCADOPAGO_PRO_PLAN_ID||''))return 'pro';
  return null;
}

export async function POST(req) {
  try {
    const body = await req.json().catch(() => ({}));
    const {dataId,type}=notificationData(req.url,body);
    if(!dataId)return NextResponse.json({ok:true,ignored:'missing_data_id'});
    if(type && type!=='subscription_preapproval')return NextResponse.json({ok:true,ignored:'unsupported_type'});

    // O payload é somente um aviso. O estado oficial sempre é relido na API MP.
    const subscription=await mp(`/preapproval/${encodeURIComponent(dataId)}`);
    const planCode=knownPlanCode(subscription);
    if(!planCode)return NextResponse.json({ok:true,ignored:'unknown_plan'});

    const db=admin();
    let organizationId=String(subscription.external_reference||'').trim();
    let pending=null;

    // Hosted Checkout do preapproval_plan pode não carregar external_reference
    // específico do workspace. Nesse caso resolvemos o vínculo pelo checkout
    // pendente criado antes do redirecionamento (plano + e-mail do pagador).
    if(!organizationId){
      const email=subscriptionPayerEmail(subscription);
      if(!email)return NextResponse.json({ok:true,ignored:'missing_payer_email'});
      const {data,error}=await db.from('billing_checkout_pendentes')
        .select('id,organizacao_id')
        .eq('plano_externo_id',String(subscription.preapproval_plan_id))
        .eq('pagador_email',email)
        .eq('status','pendente')
        .order('updated_at',{ascending:false})
        .limit(1)
        .maybeSingle();
      if(error)throw new Error(`Falha ao localizar checkout pendente: ${error.message}`);
      if(!data)return NextResponse.json({ok:true,ignored:'pending_checkout_not_found'});
      pending=data; organizationId=data.organizacao_id;
    }

    const {data:organization,error:orgError}=await db.from('organizacoes').select('id').eq('id',organizationId).maybeSingle();
    if(orgError)throw new Error(`Falha ao validar organização: ${orgError.message}`);
    if(!organization)return NextResponse.json({ok:true,ignored:'organization_not_found'});

    await persistSubscription(db,organizationId,subscription);
    if(pending?.id){
      await db.from('billing_checkout_pendentes').update({status:'concluido',assinatura_externa_id:subscription.id,updated_at:new Date().toISOString()}).eq('id',pending.id);
    }
    return NextResponse.json({ok:true});
  } catch (error) {
    console.error('Mercado Pago subscription webhook',error);
    return NextResponse.json({error:'Falha temporária ao processar notificação.'},{status:500});
  }
}
