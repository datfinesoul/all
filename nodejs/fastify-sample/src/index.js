import Fastify from 'fastify'
const crypto = await import('node:crypto')

const fastify = Fastify({
  logger: true
})

process.on('beforeExit', (code) => {
  console.log('Process beforeExit event with code: ', code);
})

process.on('exit', (code) => {
  console.log('Process exit event with code: ', code);
})

// Using a single function to handle multiple signals
function handle(signal) {
  console.log({signal})
  fastify.close().then(() => {
    console.log('successfully closed!')
  }, (err) => {
    console.log('an error happened', err)
  })
}

process.on('SIGINT', handle)
process.on('SIGTERM', handle)

fastify.route({
  method: 'GET',
  // TODO: should there be slashes at the end of non-root urls?
  url: '/diagnostic/',
  handler: async (request, reply) => {
    return { status: 'okay' }
  }
})

// TODO: look into UV_THREADPOOL_SIZE.  default: 4

fastify.route({
  method: 'GET',
  url: '/slow/',
  handler: async (request, reply) => {
    // NOTE: Move these two lines out of the method and compare
    const salt = crypto.randomBytes(128).toString('base64');
    const hash = crypto.pbkdf2Sync('myPassword', salt, 10000, 512, 'sha512')
    return { done: 'at-last' }
  }
})

fastify.route({
  method: 'GET',
  url: '/blocking/',
  handler: async (request, reply) => {
    const { email } = request.query
    console.log(email)
    ;/[a-z]+@[a-z]+([a-z\.]+\.)+[a-z]+/.test(email)
    return { done: 'at-last' }
  }
})

fastify.route({
  method: 'GET',
  url: '/',
  schema: {
    // request needs to have a querystring with a `name` parameter
    querystring: {
      name: { type: 'string' }
    },
    // the response needs to be an object with an `hello` property of type 'string'
    response: {
      200: {
        type: 'object',
        properties: {
          hello: { type: 'string' }
        }
      }
    }
  },
  // this function is executed for every request before the handler is executed
  preHandler: async (request, reply) => {
    // E.g. check authentication
  },
  handler: async (request, reply) => {
    return { hello: 'world', but: 'not-this' }
  }
})


const start = async () => {
  try {
    await fastify.listen({ port: 8080, host: '0.0.0.0' })
  } catch (err) {
    fastify.log.error(err)
    process.exit(1)
  }
}
start()
