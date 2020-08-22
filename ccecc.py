# ccecc.py by migeyel
# yes, this is almost certainly not as secure as a dedicated and well-reviewed cryptographic library
# but it is compatible with lib/ecc-168.lua's curve, and probably at least okay enough to not be breakable without significant work and advanced knowledge

from random import SystemRandom
from hashlib import sha256

sr = SystemRandom()
d = 122
p = 481 * 2**159 + 3
q = 87872785944520537956996543572443276895479022146391
q_high = (q & 0xffffff000000000000000000000000000000000000) >> 144
r = 2**168
rinv_p = 310071939986524294093047724006185234204379008641709
rinv_q = 36602587216183530149852253031625932170262363893516

def montgomery_mod_p(n):
	return (n * r) % p

def inv_montgomery_mod_p(n):
	return (n * rinv_p) % p

def montgomery_mod_q(n):
	return (n * r) % q

def inv_montgomery_mod_q(n):
	return (n * rinv_q) % q

class Point():
	def __init__(self, X, Y, Z):
		self.X = X
		self.Y = Y
		self.Z = Z

	def double(self):
		X1, Y1, Z1 = self.X, self.Y, self.Z

		b = (X1 + Y1) % p
		B = (b * b) % p
		C = (X1 * X1) % p
		D = (Y1 * Y1) % p
		E = (C + D) % p
		H = (Z1 * Z1) % p
		J = (E - 2 * H) % p

		X3 = ((B - E) * J) % p
		Y3 = (E * (C - D)) % p
		Z3 = (E * J) % p

		return Point(X3, Y3, Z3)

	def __add__(self, other):
		X1, Y1, Z1 = self.X, self.Y, self.Z
		X2, Y2, Z2 = other.X, other.Y, other.Z

		A = (Z1 * Z2) % p
		B = (A * A) % p
		C = (X1 * X2) % p
		D = (Y1 * Y2) % p
		E = (d * C * D) % p
		F = (B - E) % p
		G = (B + E) % p

		X3 = ((X1 + Y1) * (X2 + Y2)) % p
		X3 = (X3 - (C + D)) % p
		X3 = (F * X3) % p
		X3 = (A * X3) % p
		Y3 = (G * (D - C)) % p
		Y3 = (A * Y3) % p
		Z3 = (F * G) % p

		return Point(X3, Y3, Z3)

	def __neg__(self):
		return Point(-self.X % p, self.Y, self.Z)

	def __sub__(self, other):
		return self + (-other)

	def scale(self):
		X1, Y1, Z1 = self.X, self.Y, self.Z

		A = pow(Z1, p - 2, p)

		return Point((X1 * A) % p, (Y1 * A) % p, 1)

	def __eq__(self, other):
		X1, Y1, Z1 = self.X, self.Y, self.Z
		X2, Y2, Z2 = other.X, other.Y, other.Z

		A1 = (X1 * Z2) % p
		B1 = (Y1 * Z2) % p
		A2 = (X2 * Z1) % p
		B2 = (Y2 * Z1) % p

		return A1 == A2 and B1 == B2

	def is_on_curve(self):
		X1, Y1, Z1 = self.X, self.Y, self.Z

		X12 = (X1 * X1) % p
		Y12 = (Y1 * Y1) % p
		Z12 = (Z1 * Z1) % p
		Z14 = (Z12 * Z12) % p
		a = (X12 + Y12) % p
		a = (a * Z12) % p
		b = (d * X12 * Y12) % p
		b = (Z14 + b) % p

		return a == b

	def is_inf(self):
		return self.X == 0

	def __mul__(self, other):
		P = self
		R = Point(0, 1, 1)

		while other > 0:
			if other % 2 == 1:
				R = R + P
			P = P.double()
			other //= 2

		return R

	def encode(self):
		self = self.scale()
		x, y = self.X, self.Y
		x = montgomery_mod_p(x)
		y = montgomery_mod_p(y)
		result = y.to_bytes(21, "little")
		result += b"\1" if x % 2 == 1 else b"\0"

		return result

	@staticmethod
	def decode(enc):
		xbit = enc[-1]
		y = int.from_bytes(enc[:-1], "little")
		y = inv_montgomery_mod_p(y)
		y2 = (y * y) % p
		u = (y2 - 1) % p
		v = (d * y2 - 1) % p
		u2 = (u * u) % p
		u3 = (u * u2) % p
		u5 = (u3 * u2) % p
		v2 = (v * v) % p
		v3 = (v * v2) % p
		w = (u5 * v3) % p
		x = pow(w, (p - 3) // 4, p)
		x = (v * x) % p
		x = (u3 * x) % p
		if montgomery_mod_p(x) % 2 != xbit:
			x = p - x
		result = Point(x, y, 1)
		if not result.is_on_curve():
			raise AssertionError("invalid point")

		return result

G = Point(57011162926213840986709657235115373630724916748242, 4757975364450884908603518716754190307249787749330, 1)

def encode_mod_q(n):
	return montgomery_mod_q(n).to_bytes(21, "little")

def decode_mod_q(data):
	data = int.from_bytes(data, "little") & 0xffffffffffffffffffffffffffffffffffffffffff
	data_high = (data & 0xffffff000000000000000000000000000000000000) >> 144
	data_low = data & 0x000000ffffffffffffffffffffffffffffffffffff
	data_high = data_high % q_high
	data = data_low | (data_high << 144)
	return inv_montgomery_mod_q(data)

def hash_mod_q(data):
	return decode_mod_q(sha256(data).digest())

def keypair(seed=None):
	x = hash_mod_q(seed) if seed else sr.randrange(q)
	Y = G * x

	private_key = encode_mod_q(x)
	public_key = Y.encode()

	return private_key, public_key

def public_key(private_key):
	x = decode_mod_q(private_key)
	Y = G * x
	return Y.encode()

def exchange(private_key, public_key):
	x = decode_mod_q(private_key)
	Y = Point.decode(public_key)
	assert(Y.is_on_curve())
	Z = Y * x
	shared_secret = sha256(Z.encode()).digest()
	return shared_secret

def sign(private_key, message):
	x = decode_mod_q(private_key)
	k = sr.randrange(q)
	R = G * k
	e = hash_mod_q(message + R.encode().hex().encode())
	s = (k - x * e) % q

	e = encode_mod_q(e)
	s = encode_mod_q(s)

	return e + s

def verify(public_key, message, signature):
	Y = Point.decode(public_key)
	e = decode_mod_q(signature[:len(signature) // 2])
	s = decode_mod_q(signature[len(signature) // 2:])
	Rv = G * s + Y * e
	ev = hash_mod_q(message + Rv.encode().hex().encode())

	return ev == e