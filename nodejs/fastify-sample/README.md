```bash
hyperfine --warmup 3 --shell=none --runs 100 "curl 'http://localhost:9000/blocking/'"

# very blocking call
curl 'http://localhost:9000/blocking/?email=tom@2832baba.com...........................................'
```

- https://medium.com/voodoo-engineering/node-js-lots-of-ways-to-block-your-event-loop-and-how-to-avoid-it-b41f41deecf5
- https://hacks.mozilla.org/2018/03/es-modules-a-cartoon-deep-dive/
