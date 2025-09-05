## Thing to Remember for Istio

- Install Istio and inject Istio into a named space (if not in *ambient* mode)
    ```shell
  istioctl install -y
  kubectl label namespace namespace-where-manifests-are-deployed istio-injection=enabled
  ```
- **VirtualService** with retries and other needed features
- **Gateway** API service
- **DestinationRule**

*Use Fully Qualified Domain Names*.