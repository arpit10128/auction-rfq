-- CreateEnum
CREATE TYPE "UserRole" AS ENUM ('BUYER', 'SUPPLIER');

-- CreateEnum
CREATE TYPE "RfqStatus" AS ENUM ('DRAFT', 'PUBLISHED', 'ACTIVE', 'CLOSED', 'FORCE_CLOSED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "SupplierInvitationStatus" AS ENUM ('INVITED', 'ACCEPTED', 'DECLINED');

-- CreateEnum
CREATE TYPE "AuctionTriggerType" AS ENUM ('BID_RECEIVED', 'ANY_RANK_CHANGE', 'L1_RANK_CHANGE');

-- CreateEnum
CREATE TYPE "AuctionEventType" AS ENUM ('SUPPLIER_INVITED', 'BID_SUBMITTED', 'RANK_CHANGED', 'TIME_EXTENDED', 'AUCTION_CLOSED', 'FORCE_CLOSED');

-- CreateTable
CREATE TABLE "User" (
    "id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "password" TEXT NOT NULL,
    "role" "UserRole" NOT NULL,
    "companyName" TEXT,
    "phone" TEXT,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Rfq" (
    "id" UUID NOT NULL,
    "referenceId" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "description" TEXT,
    "buyerId" UUID NOT NULL,
    "bidStartAt" TIMESTAMPTZ(3) NOT NULL,
    "bidCloseAt" TIMESTAMPTZ(3) NOT NULL,
    "forcedBidCloseAt" TIMESTAMPTZ(3) NOT NULL,
    "serviceDate" TIMESTAMPTZ(3),
    "status" "RfqStatus" NOT NULL DEFAULT 'DRAFT',
    "auctionEnabled" BOOLEAN NOT NULL DEFAULT true,
    "triggerWindowMinutes" INTEGER NOT NULL DEFAULT 10,
    "extensionDurationMinutes" INTEGER NOT NULL DEFAULT 5,
    "extensionTrigger" "AuctionTriggerType" NOT NULL DEFAULT 'BID_RECEIVED',
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "Rfq_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "RfqSupplier" (
    "id" UUID NOT NULL,
    "rfqId" UUID NOT NULL,
    "supplierId" UUID NOT NULL,
    "status" "SupplierInvitationStatus" NOT NULL DEFAULT 'INVITED',
    "invitedAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "respondedAt" TIMESTAMPTZ(3),

    CONSTRAINT "RfqSupplier_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Bid" (
    "id" UUID NOT NULL,
    "rfqId" UUID NOT NULL,
    "supplierId" UUID NOT NULL,
    "carrierName" TEXT NOT NULL,
    "freightCharges" DECIMAL(14,2) NOT NULL,
    "originCharges" DECIMAL(14,2) NOT NULL,
    "destinationCharges" DECIMAL(14,2) NOT NULL,
    "totalAmount" DECIMAL(14,2) NOT NULL,
    "transitTime" TEXT NOT NULL,
    "validityUntil" TIMESTAMPTZ(3),
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Bid_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "AuctionEvent" (
    "id" UUID NOT NULL,
    "rfqId" UUID NOT NULL,
    "actorId" UUID,
    "bidId" UUID,
    "type" "AuctionEventType" NOT NULL,
    "message" TEXT,
    "reason" TEXT,
    "previousBidCloseAt" TIMESTAMPTZ(3),
    "newBidCloseAt" TIMESTAMPTZ(3),
    "metadata" JSONB,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AuctionEvent_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE UNIQUE INDEX "Rfq_referenceId_key" ON "Rfq"("referenceId");

-- CreateIndex
CREATE INDEX "Rfq_buyerId_idx" ON "Rfq"("buyerId");

-- CreateIndex
CREATE INDEX "Rfq_status_bidCloseAt_idx" ON "Rfq"("status", "bidCloseAt");

-- CreateIndex
CREATE INDEX "RfqSupplier_supplierId_status_idx" ON "RfqSupplier"("supplierId", "status");

-- CreateIndex
CREATE UNIQUE INDEX "RfqSupplier_rfqId_supplierId_key" ON "RfqSupplier"("rfqId", "supplierId");

-- CreateIndex
CREATE INDEX "Bid_rfqId_createdAt_idx" ON "Bid"("rfqId", "createdAt");

-- CreateIndex
CREATE INDEX "Bid_rfqId_supplierId_createdAt_idx" ON "Bid"("rfqId", "supplierId", "createdAt");

-- CreateIndex
CREATE INDEX "Bid_rfqId_totalAmount_idx" ON "Bid"("rfqId", "totalAmount");

-- CreateIndex
CREATE INDEX "AuctionEvent_rfqId_createdAt_idx" ON "AuctionEvent"("rfqId", "createdAt");

-- CreateIndex
CREATE INDEX "AuctionEvent_actorId_idx" ON "AuctionEvent"("actorId");

-- CreateIndex
CREATE INDEX "AuctionEvent_type_idx" ON "AuctionEvent"("type");

-- AddForeignKey
ALTER TABLE "Rfq" ADD CONSTRAINT "Rfq_buyerId_fkey" FOREIGN KEY ("buyerId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RfqSupplier" ADD CONSTRAINT "RfqSupplier_rfqId_fkey" FOREIGN KEY ("rfqId") REFERENCES "Rfq"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "RfqSupplier" ADD CONSTRAINT "RfqSupplier_supplierId_fkey" FOREIGN KEY ("supplierId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Bid" ADD CONSTRAINT "Bid_rfqId_fkey" FOREIGN KEY ("rfqId") REFERENCES "Rfq"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Bid" ADD CONSTRAINT "Bid_supplierId_fkey" FOREIGN KEY ("supplierId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AuctionEvent" ADD CONSTRAINT "AuctionEvent_rfqId_fkey" FOREIGN KEY ("rfqId") REFERENCES "Rfq"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AuctionEvent" ADD CONSTRAINT "AuctionEvent_actorId_fkey" FOREIGN KEY ("actorId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AuctionEvent" ADD CONSTRAINT "AuctionEvent_bidId_fkey" FOREIGN KEY ("bidId") REFERENCES "Bid"("id") ON DELETE SET NULL ON UPDATE CASCADE;
