import {NextResponse} from 'next/server';
import {admin,mp,persistSubscription} from '../_server';

function notificationData(reqUrl, body) {
  const url = new URL(reqUrl);
  const dataId =
    url.searchParams.get('data.id') ||
    url.searchParams.get('data_id') ||
    body?.data?.id ||
    body?.id ||
    null;
  const type = url.searchParams.get('type') || body?.type || body?.topic || null;
  return {dataId: dataId ? String(dataId) : null, type};
}

function isKnownPlan(subscription) {
  const planId = subscription?.preapproval_plan_id;
  return Boolean(
    planId &&
    (planId === process.env.MERCADOPAGO_PLUS_PLAN_ID ||
      planId === process.env.MERCADOPAGO_PRO_PLAN_ID)
  );
}

export async function POST(req) {
  try {
    const body = await req.json().catch(() => ({}));
    const {dataId, type} = notificationData(req.url, body);

    // Para Assinaturas, a notification_url é enviada na criação do /preapproval.
    // A notificação recebida é tratada apenas como um aviso: nenhuma informação
    // financeira do payload é usada para liberar plano. O estado oficial é
    // consultado novamente na API do Mercado Pago usando nosso Access Token.
    if (!dataId) return NextResponse.json({ok: true, ignored: 'missing_data_id'});

    // Processa o evento de vínculo/atualização da assinatura. Alguns formatos
    // antigos podem chegar sem type; nesse caso, tentamos confirmar o recurso.
    if (type && type !== 'subscription_preapproval') {
      return NextResponse.json({ok: true, ignored: 'unsupported_type'});
    }

    const subscription = await mp(`/preapproval/${encodeURIComponent(dataId)}`);

    // Defesa adicional: só aceitamos assinaturas vinculadas aos planos Plus/Pro
    // configurados nesta implantação do ContaClaraAI.
    if (!isKnownPlan(subscription)) {
      return NextResponse.json({ok: true, ignored: 'unknown_plan'});
    }

    const organizationId = String(subscription.external_reference || '');
    if (!organizationId) {
      return NextResponse.json({ok: true, ignored: 'missing_external_reference'});
    }

    const db = admin();
    const {data: organization} = await db
      .from('organizacoes')
      .select('id')
      .eq('id', organizationId)
      .maybeSingle();

    if (!organization) {
      return NextResponse.json({ok: true, ignored: 'organization_not_found'});
    }

    await persistSubscription(db, organizationId, subscription);
    return NextResponse.json({ok: true});
  } catch (error) {
    console.error('Mercado Pago subscription webhook', error);
    // Retorna 500 para permitir que o Mercado Pago faça novas tentativas em
    // falhas transitórias de API/banco. Eventos inválidos são respondidos acima.
    return NextResponse.json({error: 'Falha temporária ao processar notificação.'}, {status: 500});
  }
}
