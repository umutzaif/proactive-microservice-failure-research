# P0 servis topolojisi

Online Boutique uygulama düğümleri: `frontend`, `adservice`, `cartservice`, `checkoutservice`, `currencyservice`, `emailservice`, `paymentservice`, `productcatalogservice`, `recommendationservice`, `shippingservice`, `redis-cart`, `loadgenerator`.

Normal çağrı kenarları:

```text
loadgenerator -> frontend
frontend -> adservice
frontend -> cartservice
frontend -> checkoutservice
frontend -> currencyservice
frontend -> productcatalogservice
frontend -> recommendationservice
frontend -> shippingservice
cartservice -> redis-cart
checkoutservice -> cartservice
checkoutservice -> currencyservice
checkoutservice -> emailservice
checkoutservice -> paymentservice
checkoutservice -> productcatalogservice
checkoutservice -> shippingservice
recommendationservice -> productcatalogservice
```

Observability akışı:

```text
instrumented services -> OTLP -> opentelemetrycollector -> OTLP -> Jaeger
Kubernetes kubelet/cAdvisor -> Prometheus
service stdout/stderr -> Kubernetes container log API
```

Küme tek node'dur: `p0-online-boutique` (`192.168.49.2`), Kubernetes v1.34.0, containerd 2.2.1.

