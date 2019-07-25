resource "aws_route53_record" "cert_cdn" {
  name = "${aws_acm_certificate.cert_cdn.domain_validation_options.0.resource_record_name}"
  type = "${aws_acm_certificate.cert_cdn.domain_validation_options.0.resource_record_type}"
  zone_id = "${var.zone_id}"
  records = ["${aws_acm_certificate.cert_cdn.domain_validation_options.0.resource_record_value}"]
  ttl = 60
}

/*----------------------------*/
/*--- Certificate  Manager ---*/
/*----------------------------*/

resource "aws_acm_certificate" "cert_cdn" {
  domain_name = "${var.domain_name}"
  validation_method = "DNS"
}

resource "aws_acm_certificate_validation" "cert_cdn" {
  certificate_arn = "${aws_acm_certificate.cert_cdn.arn}"
  validation_record_fqdns = ["${aws_route53_record.cert_cdn.fqdn}"]
}


