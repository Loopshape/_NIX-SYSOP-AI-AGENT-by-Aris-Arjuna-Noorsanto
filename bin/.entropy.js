#!/usr/bin/env node
// ~/.bin/.entropy.js
import crypto from 'crypto'
import fs from 'fs'

function entropyTick() {
  const now = Date.now()
  const seed = crypto.randomBytes(32).toString('hex')
  const hash = crypto.createHash('sha256').update(seed + now).digest('hex')

  const tick = {
    time: new Date().toISOString(),
    unit: (now / 7500) % 8, // 8 units per 2π per minute
    hash
  }

  fs.writeFileSync('/tmp/entropy_tick.json', JSON.stringify(tick))
  console.log('Entropy Tick:', tick)
}
setInterval(entropyTick, 60 * 1000 / 8) // every 7.5s (8x per minute)
