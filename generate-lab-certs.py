"""Generate a local-only CA and LDAPS certificate; requires cryptography."""
from datetime import datetime, timedelta, timezone
from ipaddress import ip_address
from pathlib import Path
from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.x509.oid import NameOID, ExtendedKeyUsageOID

folder = Path(__file__).resolve().parent / 'ldap' / 'certs'
folder.mkdir(parents=True, exist_ok=True)
if any(folder.glob('*.pem')) or any(folder.glob('*.crt')) or any(folder.glob('*.key')):
    raise SystemExit('Certificates already exist; refusing to overwrite. Back them up before renewal.')
now = datetime.now(timezone.utc)
ca_key = rsa.generate_private_key(public_exponent=65537, key_size=3072)
server_key = rsa.generate_private_key(public_exponent=65537, key_size=3072)
ca_name = x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, 'Dashboard local lab CA')])
ca = (x509.CertificateBuilder().subject_name(ca_name).issuer_name(ca_name)
      .public_key(ca_key.public_key()).serial_number(x509.random_serial_number())
      .not_valid_before(now - timedelta(minutes=5)).not_valid_after(now + timedelta(days=365))
      .add_extension(x509.BasicConstraints(ca=True, path_length=0), critical=True)
      .add_extension(x509.KeyUsage(digital_signature=True, key_encipherment=False,
          content_commitment=False, data_encipherment=False, key_agreement=False,
          key_cert_sign=True, crl_sign=True, encipher_only=None, decipher_only=None), critical=True)
      .add_extension(x509.SubjectKeyIdentifier.from_public_key(ca_key.public_key()), critical=False)
      .sign(ca_key, hashes.SHA256()))
server = (x509.CertificateBuilder()
          .subject_name(x509.Name([x509.NameAttribute(NameOID.COMMON_NAME, 'openldap')]))
          .issuer_name(ca_name).public_key(server_key.public_key())
          .serial_number(x509.random_serial_number())
          .not_valid_before(now - timedelta(minutes=5)).not_valid_after(now + timedelta(days=90))
          .add_extension(x509.BasicConstraints(ca=False, path_length=None), critical=True)
          .add_extension(x509.SubjectAlternativeName([x509.DNSName('openldap'), x509.DNSName('localhost'),
                          x509.IPAddress(ip_address('127.0.0.1'))]), critical=False)
          .add_extension(x509.ExtendedKeyUsage([ExtendedKeyUsageOID.SERVER_AUTH]), critical=False)
          .add_extension(x509.AuthorityKeyIdentifier.from_issuer_public_key(ca_key.public_key()), critical=False)
          .sign(ca_key, hashes.SHA256()))
for name, cert in [('ca.crt', ca), ('ldap.crt', server)]:
    (folder / name).write_bytes(cert.public_bytes(serialization.Encoding.PEM))
# The CA private key is not retained: regenerate the lab trust chain when renewing.
(folder / 'ldap.key').write_bytes(server_key.private_bytes(serialization.Encoding.PEM,
    serialization.PrivateFormat.TraditionalOpenSSL, serialization.NoEncryption()))
print('Created lab CA and LDAPS certificate under ldap/certs (gitignored).')
