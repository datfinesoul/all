let mockRest
jest.mock('@octokit/rest', () => {
  mockRest = {
    issues: {
      get: jest.fn(),
      listComments: jest.fn(),
      createComment: jest.fn(),
      updateComment: jest.fn()
    },
    rateLimit: {
      get: jest.fn()
    }
  }
  return { Octokit: function () { this.rest = mockRest } }
})

describe('GitHub', () => {
  const envBackup = process.env
  let index

  beforeEach(() => {
    jest.resetModules()
    process.env = { ...envBackup } // Make a copy

    // These 3 lines can move into the tests if that granularity is needed
    process.env.GITHUB_REPOSITORY = 'my/repo'
    process.env.WORKER_SERVICE_ACCOUNT_ID = 4000
    index = require('../index')
  })

  afterAll(() => {
    process.env = envBackup // Restore old environment
  })

  describe('bla', () => {
    test('foo', async () => {
      const data = {
      }
      mockRest.issues.get.mockResolvedValue({ data })
      expect(mockRest.issues.get).toHaveBeenCalledTimes(1)
      expect(mockRest.issues.get).toHaveBeenCalledWith({
      })
      expect(result).toEqual({
      })
    })
  })
})
