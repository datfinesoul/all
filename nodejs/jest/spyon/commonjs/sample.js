'use strict'

const constArrow = () => {
  console.log('[i] constArrow')
  process.env.TEST_CONST_ARROW = 'set'
  return 111
}

const constArrowAsync = async () => {
  console.log('[i] constArrowAsync')
}

const constArrowPrivate = () => {
  console.log('[i] constArrowPrivate')
  return 222
}

module.exports = {
  constArrow,
  constArrowAsync,
  __private__: {
    constArrowPrivate
  }
}
