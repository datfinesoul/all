describe('Common', () => {
  // Make a copy of the environment variables
  const envBackup = process.env
  let sample

  beforeEach(() => {
    // Reset the environment variables with a shallow clone
    process.env = { ...envBackup }

    // Set any custom environment variables here, move this to the tests if
    //   more granularity is needed
    // process.env.bla = 1

    sample = require('../sample')
    // Testing the the environment variables were restored
    //console.log('[i] process.env.TEST_CONST_ARROW', process.env.TEST_CONST_ARROW)
  })

  afterEach(() => {
    jest.restoreAllMocks()
  })

  afterAll(() => {
    // After all the tests in this file are done, restore the environment
    process.env = envBackup
  })

  test('constArrow', () => {
    const spy = jest.spyOn(sample, 'constArrow').mockReturnValue(222)
    const result = sample.constArrow()
    expect(spy).toHaveBeenCalled()
    expect(result).toEqual(222)
  })

  test('constArrowAsync', async () => {
    const spy = jest.spyOn(sample, 'constArrowAsync').mockResolvedValue(333)
    const result = await sample.constArrowAsync()
    expect(spy).toHaveBeenCalled()
    expect(result).toEqual(333)
  })

  test('constArrowPrivate:jest should not be able to spy on this', async () => {
    function thisWillFail() {
      jest.spyOn(sample, 'constArrowPrivate')
    }
    expect(thisWillFail).toThrow('Property `constArrowPrivate` does not exist in the provided object')
  })

  test('constArrowPrivate:exported', async () => {
    const spy = jest.spyOn(sample.__private__, 'constArrowPrivate')
    const result = sample.__private__.constArrowPrivate()
    expect(spy).toHaveBeenCalled()
    expect(result).toEqual(222)
  })

  test('constArrowPrivate:exported:mock', async () => {
    const spy = jest.spyOn(sample.__private__, 'constArrowPrivate').mockReturnValue(444)
    const result = sample.__private__.constArrowPrivate()
    expect(spy).toHaveBeenCalled()
    expect(result).toEqual(444)
  })
  test('constArrowPrivate:exported', async () => {
    const spy = jest.spyOn(sample.__private__, 'constArrowPrivate').mockReturnValue(444)
    const result = sample.__private__.constArrowPrivate()
    expect(spy).toHaveBeenCalled()
    expect(result).toEqual(444)
  })

  test('random', () => {
  })
})
