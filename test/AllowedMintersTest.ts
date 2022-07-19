import { expect } from "chai";
import "@nomiclabs/hardhat-ethers";
import { ethers, deployments } from "hardhat";
import parseDataURI from "data-urls";

import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import {
  DropCreator,
  SingleEditionMintable,
} from "../typechain";

describe("AllowedMinters", () => {
  let signer: SignerWithAddress;
  let signerAddress: string;
  let dynamicSketch: DropCreator;

  beforeEach(async () => {
    const { DropCreator } = await deployments.fixture([
      "DropCreator",
      "SingleEditionMintable",
    ]);
    const dynamicMintableAddress = (
      await deployments.get("SingleEditionMintable")
    ).address;
    dynamicSketch = (await ethers.getContractAt(
      "DropCreator",
      DropCreator.address
    )) as DropCreator;

    signer = (await ethers.getSigners())[0];
    signerAddress = await signer.getAddress();
  });

  it("makes a new edition", async () => {
    const artist = (await ethers.getSigners())[1];
    const artistAddress = await signer.getAddress();

    await dynamicSketch.createEdition(
      artistAddress,
      "Testing Token",
      "TEST",
      "This is a testing token for all",
      "https://ipfs.io/ipfsbafybeify52a63pgcshhbtkff4nxxxp2zp5yjn2xw43jcy4knwful7ymmgy",
      "0x0000000000000000000000000000000000000000000000000000000000000000",
      "",
      "0x0000000000000000000000000000000000000000000000000000000000000000",
      // 1% royalty since BPS
      10,
      10,
      // 50% split since BPS
      500
    );

    const editionResult = await dynamicSketch.getEditionAtId(0);
    const minterContract = (await ethers.getContractAt(
      "SingleEditionMintable",
      editionResult
    )) as SingleEditionMintable;
    expect(await minterContract.name()).to.be.equal("Testing Token");
    expect(await minterContract.symbol()).to.be.equal("TEST");
    const editionUris = await minterContract.getURIs();
    expect(editionUris[0]).to.be.equal("");
    expect(editionUris[1]).to.be.equal(
      "0x0000000000000000000000000000000000000000000000000000000000000000"
    );
    expect(editionUris[2]).to.be.equal(
      "https://ipfs.io/ipfsbafybeify52a63pgcshhbtkff4nxxxp2zp5yjn2xw43jcy4knwful7ymmgy"
    );
    expect(editionUris[3]).to.be.equal(
      "0x0000000000000000000000000000000000000000000000000000000000000000"
    );
    expect(await minterContract.editionSize()).to.be.equal(10);
    // TODO(iain): check bps
    expect(await minterContract.owner()).to.be.equal(signerAddress);
  });
});
