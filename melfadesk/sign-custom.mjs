// Signs custom.json into custom.txt: base64 of the 64 byte Ed25519 signature followed by the JSON (libsodium "signed message").
// usage: node sign-custom.mjs <private key .pem, kept outside the repository> <custom.json> <custom.txt>
import { createPrivateKey, createPublicKey, sign, verify } from 'node:crypto';
import { readFileSync, writeFileSync } from 'node:fs';

const [keyPath, inputPath, outputPath] = process.argv.slice(2);
if (!outputPath) throw new Error('usage: node sign-custom.mjs <private.pem> <custom.json> <custom.txt>');
const key = createPrivateKey(readFileSync(keyPath));
const message = Buffer.from(JSON.stringify(JSON.parse(readFileSync(inputPath, 'utf8'))), 'utf8');
const signature = sign(null, message, key);
const publicKey = createPublicKey(key);
if (!verify(null, message, publicKey, signature)) throw new Error('the signature does not verify');
writeFileSync(outputPath, Buffer.concat([signature, message]).toString('base64'));
console.log('public key:', publicKey.export({ type: 'spki', format: 'der' }).subarray(-32).toString('base64'));
