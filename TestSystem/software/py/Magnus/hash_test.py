import hmac
import base64

key = b"itsdaq_database"
myhash = base64.b64encode(hmac.new(key, b"12344525" * 100100).digest())
print(myhash)
