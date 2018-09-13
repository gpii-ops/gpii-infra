/*

Template for adding Google Cloud IAM role bindings to users or serviceAccounts


# Full control over the kerring and all encryption keys in it
resource "google_kms_key_ring_iam_binding" "keyring_admins" {
  key_ring_id = ""
  role        = "roles/cloudkms.admin"

  members = []
}

# Access to all encryption keys
resource "google_kms_key_ring_iam_binding" "keyring_users" {
  key_ring_id = ""
  role        = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  members = []
}

resource "google_kms_crypto_key_iam_binding" "cryptokey_users" {
  crypto_key_id = ""
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  members = []
}


# Allow fetching and pushing secrets in the bucket
resource "google_storage_bucket_iam_binding" "bucket_admins" {
  bucket = ""

  role = "roles/storage.objectAdmin"

  members = []
}
*/

