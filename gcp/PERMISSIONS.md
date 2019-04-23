This document is meant to be a description of the accounts that can manage a GCP cluster of the GPII at some level. Each account has a limited set of particular permissions which has been assigned in order to perform the cluster tasks.

Accounts and permissions
========================

### cloud-admin@raisingthefloor.org

  This is a Google group of which all the operators are members. The members of this group only have the permissions needed to allow IAM changes in the projects of the organization.

  1. Organization Policy Administrator

### [OPERATOR]@raisingthefloor.org

  An operator is a member of the operations team, who have the privileges in the organization to manage and support the infrastructure. By default an operator doesn't have permissions to manage any resources of the organization except the IAMs. In the case of an operator needs to escalate his/her personal privileges it will be possible such grant but only for a limited period of time.

  Inherited permissions from _cloud-admin@raisingthefloor.org_ and can attach additional IAM roles just in special cases, and only for a limited period of time:

  1. Billing Account Administrator
  1. Support Account Administrator
  1. Organization Policy Administrator
  1. Security Center Viewer
  1. Viewer
  1. Owner (not attached by default)

### [DEV_USER]@raisingthefloor.org

  Developers can have their own development cluster managed by this account. This account only exists in their dev projects, where a particular user is the owner of the whole project. There is no particular owner in staging or production projects.

  1. Owner

### projectowner@gpii-common-prd.iam.gserviceaccount.com

  This service account is meant to be used by the CI in order to create the initial resources needed to execute the very first Terraform commands. This service account is present in all the projects along the organization with the roles inherited from the IAM of the organization.

  The list of the roles attached at the organization level are in the [xk_infra.rake file](../shared/rakefiles/xk_infra.rake#L1-L10), and the roles attached at each project level are also in the [xk_infra.rake file](../shared/rakefiles/xk_infra.rake#L78).

### projectowner@gpii-gcp-[ENV].iam.gserviceaccount.com

  This is the common service account that is allowed to manage the initial resources needed to create all the infrastructure in the projects. This service account is meant to be used by the CI.

  The list of the roles attached are in the [gcp-project module](../common/modules/gcp-project/main.tf#L75-L178)

  *Note that the `projectowner@gpii-common-prd.iam.gserviceaccount.com` is the owner of the gpii-common-prd project*

### [PROJECT_NUMBER]-compute@developer.gserviceaccount.com

  Compute Engine default service account

  1. Editor

### [PROJECT_NUMBER]@cloudservices.gserviceaccount.com (Google-managed service account)

  Google-managed service account used to access the APIs of Google Cloud Platform services.

  1. Editor

### service-[PROJECT_NUMBER]@compute-system.iam.gserviceaccount.com (Google-managed service account)

  Google-managed service account used to access the APIs of Google Cloud Platform services.

  1. Compute Engine Service Agent

### service-[PROJECT_NUMBER]@container-engine-robot.iam.gserviceaccount.com (Google-managed service account)

  Google-managed service account used to access the APIs of Google Cloud Platform services.

  1. Kubernetes Engine Service Agent

### service-[PROJECT_NUMBER]@containerregistry.iam.gserviceaccount.com (Google-managed service account)

  Google-managed service account used to access the APIs of Google Cloud Platform services.

  1. Editor

Privilege escalation
====================

If you are an operator and you need to assign new permissions to your user in order to make changes in a cluster or if you want to manage Security Command Center settings or security sources, you will need to attach the following IAM roles to your user:

* `roles/owner` in the current project.
* `roles/iam.serviceAccountAdmin` in the current organization.
* `roles/securitycenter.admin` in the current organization.

This can be done with the following rake commands:

* `rake grant_project_admin` attaches the owner role in the current project to the current user account.
* `rake revoke_project_admin` removes the owner role in the current project from the current user account.
* `rake grant_org_admin` attaches organization-level super user roles to the current user account.
* `rake revoke_org_admin` removes organization-level super user roles from the current user account.

Or if you working with other developer's dev project:

* `USER=<developer_user> rake grant_project_admin`
* `USER=<developer_user> rake revoke_project_admin`
