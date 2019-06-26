# ss-mirror

> Base on WebSocket proxy, deploy on HeroKu.

## Usage

1. Fork this project.
2. Create new App in Heroku.
3. Deploy branch in Heroku.
4. Set the password and method, support: `rc4-md5` `aes-256-cfb` `camellia-256-cfb`.
5. Clone this project and install dependencies.
6. Fill in the `config.json` information.
7. `npm run proxy`.
8. Then it will output: `server listening at { address: '127.0.0.1', family: 'IPv4', port: 1081 }`
9. OK, enjoy it! 🤡

## Tips

* Download [SwitchyOmega.crx](https://github.com/FelisCatus/SwitchyOmega/releases)
* This project fork from `shadowsocks-heroku`, you can find it on GitHub

## License

MIT
