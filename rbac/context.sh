kubectl config set-credentials my-user --token=<token-from-svc-acoount>

kubectl config set-context devops-context \
 --cluster=common-west.k8s.eteration.com \
 --user=my-user \
 --namespace=default
