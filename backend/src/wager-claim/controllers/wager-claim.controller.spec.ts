import { Test, TestingModule } from '@nestjs/testing';
import { WagerClaimController } from './wager-claim.controller';
import { WagerClaimService } from '../services/wager-claim.service';
import { CreateWagerClaimDto } from '../dtos/wager-claim.dto';
import { BadRequestException } from '@nestjs/common';
import { RejectWagerClaim } from '@prisma/client';

describe('WagerClaimController', () => {
  let controller: WagerClaimController;

  const mockWagerClaimService = {
    createClaim: jest.fn(),
    acceptClaim: jest.fn(),
    rejectClaim: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [WagerClaimController],
      providers: [
        { provide: WagerClaimService, useValue: mockWagerClaimService },
      ],
    }).compile();

    controller = module.get<WagerClaimController>(WagerClaimController);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  it('should call service and return created claim', async () => {
    const dto: CreateWagerClaimDto = {
      wagerId: '1',
      claimedById: '1',
      status: 'pending',
    };
    const mockClaim = { id: '1', ...dto };

    mockWagerClaimService.createClaim.mockResolvedValue(mockClaim);

    const result = await controller.create(dto);

    expect(result).toEqual(mockClaim);
    expect(mockWagerClaimService.createClaim).toHaveBeenCalledWith(dto);
    expect(mockWagerClaimService.createClaim).toHaveBeenCalledTimes(1);
  });

  it('should throw an error if service throws', async () => {
    const dto: CreateWagerClaimDto = {
      wagerId: '1',
      claimedById: '1',
      status: 'pending',
    };

    mockWagerClaimService.createClaim.mockRejectedValue(
      new BadRequestException(),
    );
    await expect(controller.create(dto)).rejects.toThrow(
      new BadRequestException(),
    );
  });

  it('should call service and accept a wager claim', async () => {
    const claimId = '1';
    const mockAcceptedClaim = { id: claimId, status: 'accepted' };

    mockWagerClaimService.acceptClaim.mockResolvedValue(mockAcceptedClaim);

    const result = await controller.accept(claimId);

    expect(result).toEqual(mockAcceptedClaim);
    expect(mockWagerClaimService.acceptClaim).toHaveBeenCalledWith(claimId);
    expect(mockWagerClaimService.acceptClaim).toHaveBeenCalledTimes(1);
  });

  it('should throw an error if wager claim service throws', async () => {
    const claimId = '1';
    mockWagerClaimService.acceptClaim.mockRejectedValue(
      new BadRequestException(),
    );

    await expect(controller.accept(claimId)).rejects.toThrow(
      new BadRequestException(),
    );
  });

  it('should call service and reject a claim', async () => {
    const dto: RejectWagerClaim = {
      id: '1',
      wagerClaimId: '1',
      reason: 'Invalid claim',
      proofFile: null,
      proofLink: 'https://example.com/proof',
      status: 'rejected',
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    mockWagerClaimService.rejectClaim.mockResolvedValue(dto);

    const result = await controller.reject(dto);

    expect(result).toEqual(dto);
    expect(mockWagerClaimService.rejectClaim).toHaveBeenCalledWith(dto);
    expect(mockWagerClaimService.rejectClaim).toHaveBeenCalledTimes(1);
  });

  it('should throw an error if reject wager claim service throws', async () => {
    const dto: RejectWagerClaim = {
      id: '1',
      wagerClaimId: '1',
      reason: 'Invalid claim',
      proofFile: null,
      proofLink: 'https://example.com/proof',
      status: 'rejected',
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    mockWagerClaimService.rejectClaim.mockRejectedValue(
      new BadRequestException(),
    );

    await expect(controller.reject(dto)).rejects.toThrow(
      new BadRequestException(),
    );
  });
});
