// Copyright (c) 2017, 2019, Oracle and/or its affiliates. All rights reserved.

variable "tenancy_ocid" {}

variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "compartment_ocid" {}

variable "region" {
  default = "us-ashburn-1"
}

variable "node_pool_ssh_public_key" {
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDZUL5w4JXDirnYLwlBjhm8SV/INNuUIKp4WBuEk8WAzin/Zmr6MocUEyB/JijFwTpsp4ZKAreHS1uE/fLsq7G0uPbxKjLx+Y9C2BKeA/jzam1j6WddH6OFx/u2HjwfnowZqqRapltpCJFn5HIk0vV8cbRbWMEeOqUg0AQO3yM+dmMgbIzRmB65coDMhoP2dCDoejZblPwhkhX6r5CxlrPyLFhAJwHkkOAFNmFzvSgymOneCw/eGtZDk1xWHE6iBlbWPdhqlhRoqs0JSdYMXBQgDXclFkAZaky8wf+je3RS2dpVAu4riOBraIOg7w3cHx5AtcBOnX3ArezBC8Vm365t"
}

provider "oci" {
  version          = ">3.0.0"
  region           = "${var.region}"
  tenancy_ocid     = "${var.tenancy_ocid}"
  user_ocid        = "${var.user_ocid}"
  fingerprint      = "${var.fingerprint}"
  private_key_path = "${var.private_key_path}"
}

data "oci_identity_availability_domain" "ad1" {
  compartment_id = "${var.tenancy_ocid}"
  ad_number      = 1
}

data "oci_identity_availability_domain" "ad2" {
  compartment_id = "${var.tenancy_ocid}"
  ad_number      = 2
}

resource "oci_core_vcn" "test_vcn" {
  cidr_block     = "10.0.0.0/16"
  compartment_id = "${var.compartment_ocid}"
  display_name   = "tfVcnForClusters"
}

resource "oci_core_internet_gateway" "test_ig" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "tfClusterInternetGateway"
  vcn_id         = "${oci_core_vcn.test_vcn.id}"
}

resource "oci_core_route_table" "test_route_table" {
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${oci_core_vcn.test_vcn.id}"
  display_name   = "tfClustersRouteTable"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = "${oci_core_internet_gateway.test_ig.id}"
  }
}

resource "oci_core_subnet" "clusterSubnet_1" {
  #Required
  availability_domain = "${data.oci_identity_availability_domain.ad1.name}"
  cidr_block          = "10.0.20.0/24"
  compartment_id      = "${var.compartment_ocid}"
  vcn_id              = "${oci_core_vcn.test_vcn.id}"

  # Provider code tries to maintain compatibility with old versions.
  security_list_ids = ["${oci_core_vcn.test_vcn.default_security_list_id}"]
  display_name      = "tfSubNet1ForClusters"
  route_table_id    = "${oci_core_route_table.test_route_table.id}"
}

resource "oci_core_subnet" "clusterSubnet_2" {
  #Required
  availability_domain = "${data.oci_identity_availability_domain.ad2.name}"
  cidr_block          = "10.0.21.0/24"
  compartment_id      = "${var.compartment_ocid}"
  vcn_id              = "${oci_core_vcn.test_vcn.id}"
  display_name        = "tfSubNet1ForClusters"

  # Provider code tries to maintain compatibility with old versions.
  security_list_ids = ["${oci_core_vcn.test_vcn.default_security_list_id}"]
  route_table_id    = "${oci_core_route_table.test_route_table.id}"
}

resource "oci_core_subnet" "nodePool_Subnet_1" {
  #Required
  availability_domain = "${data.oci_identity_availability_domain.ad1.name}"
  cidr_block          = "10.0.22.0/24"
  compartment_id      = "${var.compartment_ocid}"
  vcn_id              = "${oci_core_vcn.test_vcn.id}"

  # Provider code tries to maintain compatibility with old versions.
  security_list_ids = ["${oci_core_vcn.test_vcn.default_security_list_id}"]
  display_name      = "tfSubNet1ForNodePool"
  route_table_id    = "${oci_core_route_table.test_route_table.id}"
}

resource "oci_core_subnet" "nodePool_Subnet_2" {
  #Required
  availability_domain = "${data.oci_identity_availability_domain.ad2.name}"
  cidr_block          = "10.0.23.0/24"
  compartment_id      = "${var.compartment_ocid}"
  vcn_id              = "${oci_core_vcn.test_vcn.id}"

  # Provider code tries to maintain compatibility with old versions.
  security_list_ids = ["${oci_core_vcn.test_vcn.default_security_list_id}"]
  display_name      = "tfSubNet2ForNodePool"
  route_table_id    = "${oci_core_route_table.test_route_table.id}"
}

resource "oci_containerengine_cluster" "test_cluster" {
  #Required
  compartment_id     = "${var.compartment_ocid}"
  kubernetes_version = "${data.oci_containerengine_cluster_option.test_cluster_option.kubernetes_versions.0}"
  name               = "tfTestCluster"
  vcn_id             = "${oci_core_vcn.test_vcn.id}"

  #Optional
  options {
    service_lb_subnet_ids = ["${oci_core_subnet.clusterSubnet_1.id}", "${oci_core_subnet.clusterSubnet_2.id}"]

    #Optional
    add_ons {
      #Optional
      is_kubernetes_dashboard_enabled = "true"
      is_tiller_enabled               = "true"
    }

    kubernetes_network_config {
      #Optional
      pods_cidr     = "10.1.0.0/16"
      services_cidr = "10.2.0.0/16"
    }
  }
}

resource "oci_containerengine_node_pool" "test_node_pool" {
  #Required
  cluster_id         = "${oci_containerengine_cluster.test_cluster.id}"
  compartment_id     = "${var.compartment_ocid}"
  kubernetes_version = "${data.oci_containerengine_node_pool_option.test_node_pool_option.kubernetes_versions.0}"
  name               = "tfPool"
  node_shape         = "VM.Standard2.1"
  subnet_ids         = ["${oci_core_subnet.nodePool_Subnet_1.id}", "${oci_core_subnet.nodePool_Subnet_2.id}"]

  #Optional
  initial_node_labels {
    #Optional
    key   = "key"
    value = "value"
  }

  node_source_details {
    #Required
    image_id    = "${data.oci_containerengine_node_pool_option.test_node_pool_option.sources.0.image_id}"
    source_type = "${data.oci_containerengine_node_pool_option.test_node_pool_option.sources.0.source_type}"
  }

  quantity_per_subnet = 2
  ssh_public_key      = "${var.node_pool_ssh_public_key}"
}

output "cluster" {
  value = {
    id                 = "${oci_containerengine_cluster.test_cluster.id}"
    kubernetes_version = "${oci_containerengine_cluster.test_cluster.kubernetes_version}"
    name               = "${oci_containerengine_cluster.test_cluster.name}"
  }
}

output "node_pool" {
  value = {
    id                 = "${oci_containerengine_node_pool.test_node_pool.id}"
    kubernetes_version = "${oci_containerengine_node_pool.test_node_pool.kubernetes_version}"
    name               = "${oci_containerengine_node_pool.test_node_pool.name}"
    subnet_ids         = "${oci_containerengine_node_pool.test_node_pool.subnet_ids}"
  }
}

data "oci_containerengine_cluster_option" "test_cluster_option" {
  cluster_option_id = "all"
}

data "oci_containerengine_node_pool_option" "test_node_pool_option" {
  node_pool_option_id = "all"
}

output "cluster_kubernetes_versions" {
  value = ["${data.oci_containerengine_cluster_option.test_cluster_option.kubernetes_versions}"]
}

output "node_pool_kubernetes_version" {
  value = ["${data.oci_containerengine_node_pool_option.test_node_pool_option.kubernetes_versions}"]
}

data "oci_containerengine_cluster_kube_config" "test_cluster_kube_config" {
  #Required
  cluster_id = "${oci_containerengine_cluster.test_cluster.id}"

  #Optional
  token_version = "2.0.0"
}

resource "local_file" "test_cluster_kube_config_file" {
  content  = "${data.oci_containerengine_cluster_kube_config.test_cluster_kube_config.content}"
  filename = "${path.module}/test_cluster_kubeconfig"
}

data "oci_identity_availability_domains" "test_availability_domains" {
  compartment_id = "${var.tenancy_ocid}"
}

variable "InstanceImageOCID" {
  type = "map"

  default = {
    // See https://docs.us-phoenix-1.oraclecloud.com/images/
    // Oracle-provided image "Oracle-Linux-7.5-2018.10.16-0"
    us-phoenix-1 = "ocid1.image.oc1.phx.aaaaaaaadjnj3da72bztpxinmqpih62c2woscbp6l3wjn36by2cvmdhjub6a"

    us-ashburn-1   = "ocid1.image.oc1.iad.aaaaaaaawufnve5jxze4xf7orejupw5iq3pms6cuadzjc7klojix6vmk42va"
    eu-frankfurt-1 = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaagbrvhganmn7awcr7plaaf5vhabmzhx763z5afiitswjwmzh7upna"
    uk-london-1    = "ocid1.image.oc1.uk-london-1.aaaaaaaajwtut4l7fo3cvyraate6erdkyf2wdk5vpk6fp6ycng3dv2y3ymvq"
  }
}
