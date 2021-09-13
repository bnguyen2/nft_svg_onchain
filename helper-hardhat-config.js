const networkConfig = {
  31337: {
    name: 'localhost',
    keyHash:
      '0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4',
    fee: '1000000000000000000', // JUELS / WEI
  },
  4: {
    name: 'rinkeby',
    linkToken: '0x01be23585060835e02b77ef475b0cc51aa1e0709',
    vrfCoordinator: '0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B',
    keyHash:
      '0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311',
    fee: '100000000000000000', // JUELS / WEI
  },
};

module.exports = {
  networkConfig,
};
