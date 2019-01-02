This document is meant to be a description of the accounts that can manage a GCP cluster of the GPII at some level. Each account has a limited set of particular permissions which has been assigned in order to perform the cluster tasks.

Accounts and permissions
========================

### cloud-admin@raisingthefloor.org

  This is a Google group where all the operators are members. The members of this group only have the permissions needed to allow IAM changes in the projects of the organization.

  1. Organization Administrator

### operator@raisingthefloor.org

  By default an operator doesn't have permissions to manage any resources of the organization except the IAMs. In the case of an operator needs to escalate his/her personal privileges it will be possible such grant but only for a limited period of time.

  Inherited permissions from _cloud-admin@raisingthefloor.org_ and can attach IAM roles just in special cases, and only for a limited period of time:

  1. Billing Account Administrator
  1. Support Account Administrator
  1. Organization Policy Administrator
  1. Owner

### dev-user@raisingthefloor.org

  This account only exists in the _dev_ projects, where a particular user is the owner of the hole project. In the case of the STG and PRD projects there is not a particular owner.

  1. Owner

### projectowner@gpii-common-prd.iam.gserviceaccount.com

  This is the common service account that is allowed to manage the initial resources needed to create all the infrastructure in the projects. This service account is meant to be used by the CI.

  1. DNS Administrator
  1. Service Account Key Admin
  1. Project IAM Admin
  1. Service Usage Admin
  1. Storage Admin
  1. Project Billing Manager
  1. Service Account Admin

### projectowner@gpii-gcp-$ENV(-$USER).iam.gserviceaccount.com

  This service account is used by the GPII-infra code to perform all the operations in each project

  1. Cloud KMS Admin
  1. Cloud KMS CryptoKey Encrypter/Decrypter
  1. Compute Admin
  1. Kubernetes Engine Admin
  1. Kubernetes Engine Cluster Admin
  1. DNS Administrator
  1. Service Account Key Admin
  1. Service Account User
  1. Logs Configuration Writer
  1. Monitoring Editor
  1. Project IAM Admin
  1. Service Usage Admin
  1. Storage Admin

### [PROJECT_NUMBER]-compute@developer.gserviceaccount.com   

  Compute Engine default service account

  1. Editor

### [PROJECT_NUMBER]@cloudbuild.gserviceaccount.com

  Cloud Build default service account

  1. Cloud Build Service Account

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

If you are an operator and you need to assign new permissions to your user in order to make changes in a cluster you will need to attach some IAM roles to your user.

Rake commands:

  * `rake grant_owner_role` Attaches the owner role to the current user account
  * `rake revoke_owner_role` Removes the owner role from the current user account