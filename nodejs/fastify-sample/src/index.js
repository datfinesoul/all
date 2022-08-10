import Fastify from 'fastify'

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
    return { helo: 'world' }
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
