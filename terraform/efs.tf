resource "aws_efs_file_system" "minecraft" {
  creation_token = "minecraft-data"
  encrypted      = true

  tags = {
    Name = "minecraft-data"
  }
}

resource "aws_efs_mount_target" "minecraft" {
  for_each        = toset(data.aws_subnets.default.ids)
  file_system_id  = aws_efs_file_system.minecraft.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs.id]
}
