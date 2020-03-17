# content and filename change
resource "local_file" "aaa_more_change" {
  content  = "bar!"
  filename = "bazz.bazz"
}

# content changes
resource "local_file" "bbb_less_change" {
  content  = "bar!"
  filename = "foo.bar"
}

# content and filename change
resource "local_file" "ccc_more_change" {
  content  = "bar!"
  filename = "bazz.bazz"
}
