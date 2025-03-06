import { Test, TestingModule } from '@nestjs/testing';
import { WagerClaimController } from './wager-claim.controller';
import { WagerClaimService } from '../services/wager-claim.service';
import { CreateWagerClaimDto } from '../dtos/wager-claim.dto';
import { BadRequestException } from '@nestjs/common';
import { WagerClaim } from '@prisma/client';
import { WagerClaimStatus } from '../../common/enums/status.enums';

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
      status: WagerClaimStatus.PENDING,
    };
    const mockReq = {
      user: { sub: 'user123' },
    };
    const mockClaim = { id: '1', ...dto, claimedById: 'user123' };

    mockWagerClaimService.createClaim.mockResolvedValue(mockClaim);

    const result = await controller.create(dto, mockReq as any);

    expect(result).toEqual(mockClaim);
    expect(mockWagerClaimService.createClaim).toHaveBeenCalledWith(
      dto,
      'user123',
    );
    expect(mockWagerClaimService.createClaim).toHaveBeenCalledTimes(1);
  });

  it('should throw an error if service throws', async () => {
    const dto: CreateWagerClaimDto = {
      wagerId: '1',
      status: WagerClaimStatus.PENDING,
    };
    const mockReq = {
      user: { sub: 'user123' },
    };

    mockWagerClaimService.createClaim.mockRejectedValue(
      new BadRequestException(),
    );
    await expect(controller.create(dto, mockReq as any)).rejects.toThrow(
      new BadRequestException(),
    );
  });

  it('should call service and accept a wager claim', async () => {
    const claimId = '1';
    const mockReq = {
      user: { sub: 'user123' },
    };
    const mockAcceptedClaim = { id: claimId };

    mockWagerClaimService.acceptClaim.mockResolvedValue(mockAcceptedClaim);

    const result = await controller.accept(claimId, mockReq as any);

    expect(result).toEqual(mockAcceptedClaim);
    expect(mockWagerClaimService.acceptClaim).toHaveBeenCalledWith(
      claimId,
      mockReq.user.sub,
    );
    expect(mockWagerClaimService.acceptClaim).toHaveBeenCalledTimes(1);
  });

  it('should throw an error if wager claim service throws', async () => {
    const claimId = '1';
    const mockReq = {
      user: { sub: 'user123' },
    };
    mockWagerClaimService.acceptClaim.mockRejectedValue(
      new BadRequestException(),
    );

    await expect(controller.accept(claimId, mockReq as any)).rejects.toThrow(
      new BadRequestException(),
    );
  });

  it('should call service and reject a claim', async () => {
    const dto: WagerClaim = {
      id: '1',
      reason: 'Invalid claim',
      proofFile: null,
      wagerId: null,
      claimedById: null,
      proofLink: 'https://example.com/proof',
      status: WagerClaimStatus.REJECTED,
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    const mockReq = {
      user: { sub: 'user123' },
    };

    mockWagerClaimService.rejectClaim.mockResolvedValue(dto);

    const result = await controller.reject(dto, mockReq as any);

    expect(result).toEqual(dto);
    expect(mockWagerClaimService.rejectClaim).toHaveBeenCalledWith(
      dto,
      mockReq.user.sub,
    );
    expect(mockWagerClaimService.rejectClaim).toHaveBeenCalledTimes(1);
  });

  it('should throw an error if reject wager claim service throws', async () => {
    const dto: WagerClaim = {
      id: '1',
      reason: 'Invalid claim',
      proofFile: null,
      wagerId: null,
      claimedById: null,
      proofLink: 'https://example.com/proof',
      status: WagerClaimStatus.REJECTED,
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    const mockReq = {
      user: { sub: 'user123' },
    };

    mockWagerClaimService.rejectClaim.mockRejectedValue(
      new BadRequestException(),
    );

    await expect(controller.reject(dto, mockReq as any)).rejects.toThrow(
      new BadRequestException(),
    );
  });
});
