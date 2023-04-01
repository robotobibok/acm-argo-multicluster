testing

start z pierwszego klastra z zainstalowanym acm:
oc apply -k bootstrap/namespaces
oc apply -k bootstrap/gitops-operator

zeby mozna bylo konfigurowac caly klaster, uprawnienia:
oc adm policy add-cluster-role-to-user cluster-admin -z openshift-gitops-argocd-application-controller -n openshift-gitops

mozna sie bawic bardziej detalicznie:
one or more objects failed to apply, reason: secrets is forbidden: User "system:serviceaccount:openshift-gitops:openshift-gitops-argocd-application-controller" cannot create resource "secrets" in API group "" in the namespace "openshift-config". Retrying attempt #5 at 8:17PM.


kubeseal --format yaml --controller-namespace sealed-secrets <htpasswd-secret.yaml > htpasswd-sealed.yaml

