crypto = require("crypto")
merge_sort = require("./merge_sort").merge_sort
int32Max = Math.pow(2, 32)

cachedTables = {} # password: [encryptTable, decryptTable]

getTable = (key) ->
  if cachedTables[key]
    return cachedTables[key]
  console.log "calculating ciphers"
  table = new Array(256)
  decrypt_table = new Array(256)
  md5sum = crypto.createHash("md5")
  md5sum.update key
  hash = new Buffer(md5sum.digest(), "binary")
  al = hash.readUInt32LE(0)
  ah = hash.readUInt32LE(4)
  i = 0

  while i < 256
    table[i] = i
    i++
  i = 1

  while i < 1024
    table = merge_sort(table, (x, y) ->
      ((ah % (x + i)) * int32Max + al) % (x + i) - ((ah % (y + i)) * int32Max + al) % (y + i)
    )
    i++
  i = 0
  while i < 256
    decrypt_table[table[i]] = i
    ++i
  result = [table, decrypt_table]
  cachedTables[key] = result
  result

substitute = (table, buf) ->
  i = 0

  while i < buf.length
    buf[i] = table[buf[i]]
    i++
  buf

bytes_to_key_results = {}

EVP_BytesToKey = (password, key_len, iv_len) ->
  if bytes_to_key_results["#{password}:#{key_len}:#{iv_len}"]
    return bytes_to_key_results["#{password}:#{key_len}:#{iv_len}"]
  m = []
  i = 0
  count = 0
  while count < key_len + iv_len
    md5 = crypto.createHash('md5')
    data = password
    if i > 0
      data = Buffer.concat([m[i - 1], password])
    md5.update(data)
    d = md5.digest()
    m.push(d)
    count += d.length
    i += 1
  ms = Buffer.concat(m)
  key = ms.slice(0, key_len)
  iv = ms.slice(key_len, key_len + iv_len)
  bytes_to_key_results[password] = [key, iv]
  return [key, iv]


method_supported =
  'aes-128-cfb': [16, 16]
  'aes-192-cfb': [24, 16]
  'aes-256-cfb': [32, 16]
  'bf-cfb': [16, 8]
  'camellia-128-cfb': [16, 16]
  'camellia-192-cfb': [24, 16]
  'camellia-256-cfb': [32, 16]
  'cast5-cfb': [16, 8]
  'des-cfb': [8, 8]
  'idea-cfb': [16, 8]
  'rc2-cfb': [16, 8]
  'rc4': [16, 0]
  'rc4-md5': [16, 16]
  'seed-cfb': [16, 16]


create_rc4_md5_cipher = (key, iv, op) ->
  md5 = crypto.createHash('md5')
  md5.update(key)
  md5.update(iv)
  rc4_key = md5.digest()
  if op == 1
    return crypto.createCipheriv('rc4', rc4_key, '')
  else
    return crypto.createDecipheriv('rc4', rc4_key, '')


class Encryptor
  constructor: (@key, @method) ->
    @iv_sent = false
    if @method == 'table'
      @method = null
    if @method?
      @cipher = @get_cipher(@key, @method, 1, crypto.randomBytes(32))
    else
      [@encryptTable, @decryptTable] = getTable(@key)

  get_cipher_len: (method) ->
    method = method.toLowerCase()
    m = method_supported[method]
    return m

  get_cipher: (password, method, op, iv) ->
    method = method.toLowerCase()
    password = new Buffer(password, 'binary')
    m = @get_cipher_len(method)
    if m?
      [key, iv_] = EVP_BytesToKey(password, m[0], m[1])
      if not iv?
        iv = iv_
      if op == 1
        @cipher_iv = iv.slice(0, m[1])
      iv = iv.slice(0, m[1])
      if method == 'rc4-md5'
        return create_rc4_md5_cipher(key, iv, op)
      else
        if op == 1
          return crypto.createCipheriv(method, key, iv)
        else
          return crypto.createDecipheriv(method, key, iv)

  encrypt: (buf) ->
    if @method?
      result = @cipher.update buf
      if @iv_sent
        return result
      else
        @iv_sent = true
        return Buffer.concat([@cipher_iv, result])
    else
      substitute @encryptTable, buf

  decrypt: (buf) ->
    if @method?
      if not @decipher?
        decipher_iv_len = @get_cipher_len(@method)[1]
        decipher_iv = buf.slice(0, decipher_iv_len)
        @decipher = @get_cipher(@key, @method, 0, decipher_iv)
        result = @decipher.update(buf.slice(decipher_iv_len))
        return result
      else
        result = @decipher.update(buf)
        return result
    else
      substitute @decryptTable, buf


exports.Encryptor = Encryptor
exports.getTable = getTable
