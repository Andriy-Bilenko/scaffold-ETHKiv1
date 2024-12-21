import { AbiItem, Chain, Log, PublicClient, createPublicClient, http, parseAbiItem } from "viem";
import * as chains from "viem/chains";
import deployedContracts from "~~/contracts/deployedContracts";
import { GenericContract } from "~~/utils/scaffold-eth/contract";

/* eslint-disable @typescript-eslint/no-unused-vars */
const EVENT_SIGNATURE =
  "event TokensLocked(address indexed token, address indexed user, uint256 amount, uint256 blockNumber)";

export async function GET() {
  const firstChainId: string = process.env.FIRST_CHAIN || "";
  const secondChainId: string = process.env.SECOND_CHAIN || "";
  const firstContractAddress: string = process.env.FIRST_CONTRACT || "";
  const secondContractAddress: string = process.env.SECOND_CONTRACT || "";
  const lastPollBlockNumber: string = process.env.LAST_POLL_BLOCK_NUMBER || "";

  if (!firstChainId || !secondChainId || !firstContractAddress || !secondContractAddress) {
    return new Response(JSON.stringify({ error: "Missing environment variables" }), {
      status: 400,
    });
  }

  const firstChain: Chain = getChain(firstChainId);
  //   const secondChain: Chain = getChain(secondChainId);

  const firstContract: GenericContract = getContract(firstChainId, firstContractAddress);
  //   const secondContract: GenericContract = getContract(secondChainId, secondContractAddress);

  const client: PublicClient = createPublicClient({
    chain: firstChain,
    transport: http(),
  });

  const eventSignature: AbiItem = parseAbiItem(EVENT_SIGNATURE);

  const events: Log[] = await client.getLogs({
    address: firstContract.address,
    event: eventSignature,
    fromBlock: BigInt(lastPollBlockNumber || 0),
    toBlock: "latest",
  });

  const processedEvents: { topics: string[]; data: string }[] = events.map(event => {
    return {
      topics: event.topics,
      data: event.data,
    };
  });

  return new Response(JSON.stringify({ events: processedEvents }), {
    status: 200,
    headers: {
      "Content-Type": "application/json",
    },
  });
}

function getChain(chainId: string) {
  for (const chain of Object.values(chains)) {
    if (chain.id === Number(chainId)) {
      return chain;
    }
  }

  throw new Error(`Chain with id ${chainId} not found`);
}

function getContract(chainId: string, contractAddress: string): GenericContract {
  const chainContracts = Object.entries(deployedContracts).find(e => e[0] === chainId)?.[1];

  if (!chainContracts) {
    throw new Error(`Contracts for chainId ${chainId} not found`);
  }

  const contract = Object.entries(chainContracts).find(e => e[1].address === contractAddress)?.[1];
  if (!contract) {
    throw new Error(`Contract ${contractAddress} not found for chainId ${chainId}`);
  }

  return contract;
}
