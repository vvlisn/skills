import type { Config } from '@jest/types';

const config: Config.InitialOptions = {
  preset:               'ts-jest',
  testEnvironment:      'jest-environment-jsdom',
  setupFilesAfterEach:  ['./jest.setup.ts'],
  moduleFileExtensions: ['js', 'json', 'vue', 'ts', 'tsx'],
  moduleNameMapper: {
    '^~/(.*)$':         '<rootDir>/$1',
    '^~~/(.*)$':        '<rootDir>/$1',
    '^@/(.*)$':         '<rootDir>/$1',
    '@shell/(.*)':      '<rootDir>/node_modules/@rancher/shell/$1',
    '@components/(.*)': '<rootDir>/node_modules/@rancher/components/dist/@rancher/components.common.js',
    '@hello-ext/(.*)':    '<rootDir>/pkg/hello-ext/$1',
    '@tests/(.*)':      '<rootDir>/tests/$1'
  },
  transform: {
    '^.+\\.js$':   '<rootDir>/node_modules/babel-jest',
    '.*\\.vue$':   '<rootDir>/node_modules/@vue/vue3-jest',
    '^.+\\.tsx?$': ['ts-jest', { tsconfig: '<rootDir>/tsconfig.json' }],
    '^.+\\.svg$':  '<rootDir>/tests/unit/config/svgTransform.ts'
  }
};

export default config;
