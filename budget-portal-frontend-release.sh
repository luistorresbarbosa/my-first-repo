apiVersion: apps/v1
kind: Deployment
metadata:
  name: budget-portal-frontend-release
spec:
  replicas: 1
  selector:
    matchLabels:
      app: budget-portal-frontend-release
      tier: budget-portal-frontend-release
  template:
    metadata: 
      labels:
        app: budget-portal-frontend-release
        tier: budget-portal-frontend-release
    spec: 
      containers:
        - name: budget-portal-frontend
          image: kwalit/budget-portal-frontend:v24.3.0-release
          imagePullPolicy: Always
          env:
          - name: API_HOST
            value: "http://172.16.100.72:3003"
          - name: API_VERSION
            value: "v1"
          - name: TENANT_HOST
            value: "172.16.100.72" 
      imagePullSecrets:
        - name: docker-registry-key
---
apiVersion: v1
kind: Service
metadata:
    name: budget-portal-frontend-release
spec:
    selector:
        app: budget-portal-frontend-release
    ports:
        - protocol: "TCP"
          port: 80
          targetPort: 80
    type: LoadBalancer
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: budget-portal-frontend-release
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: budget-portal-frontend-release
  minReplicas: 1
  maxReplicas: 2
  metrics:
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80


