import "dotenv/config";

import { PrismaClient } from "../src/generated/prisma/client";
import { PrismaPg } from "@prisma/adapter-pg";

const connectionString = process.env.DATABASE_URL;

if (!connectionString) {
  throw new Error("DATABASE_URL is not configured");
}

const adapter = new PrismaPg({ connectionString });

const prisma = new PrismaClient({ adapter });

async function main() {
  console.log("Starting database seed...");

  // 1. Create buyer
  const buyer = await prisma.user.upsert({
    where: { email: "buyer@example.com" },
    update: {},
    create: {
      name: "Demo Buyer",
      email: "buyer@example.com",
      password: "DEMO_HASH_REPLACE_BEFORE_LOGIN",
      role: "BUYER",
      companyName: "ABC Logistics",
    },
  });

  // 2. Create suppliers
  const supplierData = [
    {
      name: "Supplier One",
      email: "supplier1@example.com",
      companyName: "Fast Freight",
    },
    {
      name: "Supplier Two",
      email: "supplier2@example.com",
      companyName: "Global Transport",
    },
    {
      name: "Supplier Three",
      email: "supplier3@example.com",
      companyName: "Express Cargo",
    },
  ];

  const suppliers = [];

  for (const data of supplierData) {
    const supplier = await prisma.user.upsert({
      where: { email: data.email },
      update: {},
      create: {
        ...data,
        password: "DEMO_HASH_REPLACE_BEFORE_LOGIN",
        role: "SUPPLIER",
      },
    });

    suppliers.push(supplier);
  }

  // 3. Create sample RFQ
  const now = new Date();

  const bidStartAt = new Date(
    now.getTime() - 60 * 60 * 1000,
  );

  const bidCloseAt = new Date(
    now.getTime() + 24 * 60 * 60 * 1000,
  );

  const forcedBidCloseAt = new Date(
    bidCloseAt.getTime() + 2 * 60 * 60 * 1000,
  );

  const rfq = await prisma.rfq.upsert({
    where: { referenceId: "RFQ-DEMO-001" },
    update: {},
    create: {
      referenceId: "RFQ-DEMO-001",
      title: "Delhi to Mumbai Freight",
      description: "Demo British Auction RFQ",
      buyerId: buyer.id,
      bidStartAt,
      bidCloseAt,
      forcedBidCloseAt,
      status: "ACTIVE",
      auctionEnabled: true,
      triggerWindowMinutes: 10,
      extensionDurationMinutes: 5,
      extensionTrigger: "BID_RECEIVED",
    },
  });

  // 4. Invite suppliers
  for (const supplier of suppliers) {
    await prisma.rfqSupplier.upsert({
      where: {
        rfqId_supplierId: {
          rfqId: rfq.id,
          supplierId: supplier.id,
        },
      },
      update: {},
      create: {
        rfqId: rfq.id,
        supplierId: supplier.id,
        status: "ACCEPTED",
      },
    });
  }

  // 5. Create sample bids
  const bidData = [
    {
      id: "00000000-0000-4000-8000-000000000001",
      supplier: suppliers[0],
      amount: 50000,
      freight: 40000,
      origin: 5000,
      destination: 5000,
    },
    {
      id: "00000000-0000-4000-8000-000000000002",
      supplier: suppliers[1],
      amount: 47000,
      freight: 38000,
      origin: 4000,
      destination: 5000,
    },
    {
      id: "00000000-0000-4000-8000-000000000003",
      supplier: suppliers[2],
      amount: 48000,
      freight: 39000,
      origin: 4000,
      destination: 5000,
    },
  ];

  for (const item of bidData) {
    await prisma.bid.upsert({
      where: { id: item.id },
      update: {},
      create: {
        id: item.id,
        rfqId: rfq.id,
        supplierId: item.supplier.id,
        carrierName:
          item.supplier.companyName ?? item.supplier.name,
        freightCharges: item.freight,
        originCharges: item.origin,
        destinationCharges: item.destination,
        totalAmount: item.amount,
        transitTime: "3 days",
        validityUntil: new Date(
          now.getTime() + 7 * 24 * 60 * 60 * 1000,
        ),
      },
    });
  }

  // 6. Create an activity event
  await prisma.auctionEvent.upsert({
    where: {
      id: "00000000-0000-4000-8000-000000000010",
    },
    update: {},
    create: {
      id: "00000000-0000-4000-8000-000000000010",
      rfqId: rfq.id,
      actorId: buyer.id,
      type: "SUPPLIER_INVITED",
      message: "Three suppliers invited to the auction",
      metadata: {
        supplierCount: 3,
      },
    },
  });

  console.log("Database seeding completed successfully!");
  console.log({
    buyer: buyer.email,
    suppliers: suppliers.length,
    rfq: rfq.referenceId,
    bids: bidData.length,
  });
}

main()
  .catch((error) => {
    console.error("Seeding failed:", error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
