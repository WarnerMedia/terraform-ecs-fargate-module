# Allow for code reuse...
locals {
  # KMS write actions
  kms_write_actions = [
    "kms:CancelKeyDeletion",
    "kms:CreateAlias",
    "kms:CreateGrant",
    "kms:CreateKey",
    "kms:DeleteAlias",
    "kms:DeleteImportedKeyMaterial",
    "kms:DisableKey",
    "kms:DisableKeyRotation",
    "kms:EnableKey",
    "kms:EnableKeyRotation",
    "kms:Encrypt",
    "kms:GenerateDataKey",
    "kms:GenerateDataKeyWithoutPlaintext",
    "kms:GenerateRandom",
    "kms:GetKeyPolicy",
    "kms:GetKeyRotationStatus",
    "kms:GetParametersForImport",
    "kms:ImportKeyMaterial",
    "kms:PutKeyPolicy",
    "kms:ReEncryptFrom",
    "kms:ReEncryptTo",
    "kms:RetireGrant",
    "kms:RevokeGrant",
    "kms:ScheduleKeyDeletion",
    "kms:TagResource",
    "kms:UntagResource",
    "kms:UpdateAlias",
    "kms:UpdateKeyDescription",
  ]

  # KMS read actions
  kms_read_actions = [
    "kms:Decrypt",
    "kms:DescribeKey",
    "kms:List*",
  ]

  # secretsmanager write actions
  sm_write_actions = [
    "secretsmanager:CancelRotateSecret",
    "secretsmanager:CreateSecret",
    "secretsmanager:DeleteSecret",
    "secretsmanager:PutSecretValue",
    "secretsmanager:RestoreSecret",
    "secretsmanager:RotateSecret",
    "secretsmanager:TagResource",
    "secretsmanager:UntagResource",
    "secretsmanager:UpdateSecret",
    "secretsmanager:UpdateSecretVersionStage",
  ]

  # secretsmanager read actions
  sm_read_actions = [
    "secretsmanager:DescribeSecret",
    "secretsmanager:List*",
    "secretsmanager:GetRandomPassword",
    "secretsmanager:GetSecretValue",
  ]

  # list of users for policies
  user_ids = flatten([
    data.aws_caller_identity.current.user_id,
    data.aws_caller_identity.current.account_id,
    var.secrets_users
  ])

  # list of role users and users for policies
  role_and_saml_ids = flatten([
    "${aws_iam_role.app_role.unique_id}:*",
    "${aws_iam_role.ecsTaskExecutionRole.unique_id}:*",
    local.user_ids,
  ])

  sm_arn = "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:${var.app}-${var.environment}-??????"
}

# create the KMS key for this secret
resource "aws_kms_key" "sm_kms_key" {
  count       = var.secrets_manager ? 1 : 0
  description = "${var.app}-${var.environment}"
  policy      = data.aws_iam_policy_document.kms_resource_policy_doc.json
  tags = merge(
    var.tags,
    {
      "Name" = format("%s-%s", var.app, var.environment)
    },
  )
}

# alias for the key
resource "aws_kms_alias" "sm_kms_alias" {
  count         = var.secrets_manager ? 1 : 0
  name          = "alias/${var.app}-${var.environment}"
  target_key_id = aws_kms_key.sm_kms_key[0].key_id
}

# the kms key policy
data "aws_iam_policy_document" "kms_resource_policy_doc" {
  statement {
    sid    = "DenyWriteToAllExcectUsers"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions   = local.kms_write_actions
    resources = ["*"]

    condition {
      test     = "StringNotLike"
      variable = "aws:userId"
      values   = local.user_ids
    }
  }

  statement {
    sid    = "DenyReadToAllExceptRoleAndUsers"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions   = local.kms_read_actions
    resources = ["*"]

    condition {
      test     = "StringNotLike"
      variable = "aws:userId"
      values   = local.role_and_saml_ids
    }
  }

  statement {
    sid    = "AllowWriteToUsers"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions   = local.kms_write_actions
    resources = ["*"]

    condition {
      test     = "StringLike"
      variable = "aws:userId"
      values   = local.user_ids
    }
  }

  statement {
    sid    = "AllowReadRoleAndUsers"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions   = local.kms_read_actions
    resources = ["*"]

    condition {
      test     = "StringLike"
      variable = "aws:userId"
      values   = local.role_and_saml_ids
    }
  }
}

# create the secretsmanager secret
resource "aws_secretsmanager_secret" "sm_secret" {
  count                   = var.secrets_manager ? 1 : 0
  name                    = "${var.app}-${var.environment}"
  kms_key_id              = aws_kms_key.sm_kms_key[0].key_id
  tags                    = var.tags
  policy                  = data.aws_iam_policy_document.sm_resource_policy_doc.json
  recovery_window_in_days = var.secrets_manager_recovery_window_in_days
}

# create the placeholder secret json
resource "aws_secretsmanager_secret_version" "initial" {
  count         = var.secrets_manager ? 1 : 0
  secret_id     = aws_secretsmanager_secret.sm_secret[0].id
  secret_string = "{}"
}

# resource policy doc that limits access to secret
data "aws_iam_policy_document" "sm_resource_policy_doc" {
  statement {
    sid    = "DenyWriteToAllExceptUsers"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions   = local.sm_write_actions
    resources = [local.sm_arn]

    condition {
      test     = "StringNotLike"
      variable = "aws:userId"
      values   = local.user_ids
    }
  }

  statement {
    sid    = "DenyReadToAllExceptRoleAndUsers"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions   = local.sm_read_actions
    resources = [local.sm_arn]

    condition {
      test     = "StringNotLike"
      variable = "aws:userId"
      values   = local.role_and_saml_ids
    }
  }

  statement {
    sid    = "AllowWriteToUsers"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions   = local.sm_write_actions
    resources = [local.sm_arn]

    condition {
      test     = "StringLike"
      variable = "aws:userId"
      values   = local.user_ids
    }
  }

  statement {
    sid    = "AllowReadRoleAndUsers"
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions   = local.sm_read_actions
    resources = [local.sm_arn]

    condition {
      test     = "StringLike"
      variable = "aws:userId"
      values   = local.role_and_saml_ids
    }
  }
}
# The short name id of the created secret manager (if enabled)
output "secret_id" {
  value = var.secrets_manager ? aws_secretsmanager_secret.sm_secret[0].id : ""
}

# The arn of the created secret manager (if enabled)
output "secret_arn" {
  value = var.secrets_manager ? aws_secretsmanager_secret.sm_secret[0].arn : ""
}