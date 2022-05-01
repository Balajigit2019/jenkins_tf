provider "aws" {
#  shared_credentials_file = "c:/Users/bvijay062/.aws/credentials" # old version syntax and its depreciated
  shared_credentials_files = ["c:/Users/bvijay062/.aws/credentials"] # latest syntax
  region = "ap-south-1"
}