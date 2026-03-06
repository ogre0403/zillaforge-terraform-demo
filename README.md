# zillaforge-terraform-demo

**Note:**

[Zillaforge Provider](https://github.com/Zillaforge/terraform-provider-zillaforge.git) is not published on Hashicorp registry yet. We build a Terraform docker image including the pre-built Zillaforge Provider.

## Build zillaforge terraform provider docker image

```shell
$ git clone https://github.com/Zillaforge/terraform-provider-zillaforge.git
$ cd terraform-provider-zillaforge
$ make image
```

## Launch zillaforge provider in container

```shell
$ git clone https://github.com/ogre0403/zillaforge-terraform-demo
$ cd zillaforge-terraform-demo
$ docker run -ti --rm -v `pwd`:/workspace -w /workspace Zillaforge/terraform:0.0.1-alpha bash
```


## Use Terraform inside container

```shell
$ terraform init
$ terraform plan
$ terraform apply
```