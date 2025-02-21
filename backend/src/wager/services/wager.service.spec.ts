import { Test, TestingModule } from '@nestjs/testing';
import { WagerService } from './wager.service';
import { PrismaService } from 'nestjs-prisma';

import WagerStatus, { CreateWagerDto } from '../dtos/wager.dto';

describe('WagerService', () => {
  let service: WagerService;
  let prisma: PrismaService;

  const mockWager = {
    id: '1',
    name: 'Test Wager',
    description: 'Test Description',
    categoryId: '1',
    stakeAmount: 100,
    status: WagerStatus.PENDING,
    createdById: '1',
    tags: ['tag1', 'tag2'],
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        WagerService,
        {
          provide: PrismaService,
          useValue: {
            wager: {
              create: jest.fn().mockResolvedValue(mockWager),
              findMany: jest.fn().mockResolvedValue([mockWager]),
              findUnique: jest.fn().mockResolvedValue(mockWager),
            },
          },
        },
      ],
    }).compile();

    service = module.get<WagerService>(WagerService);
    prisma = module.get<PrismaService>(PrismaService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('createWager', () => {
    it('should create a wager', async () => {
      const createWagerDto: CreateWagerDto = {
        name: 'Test Wager',
        description: 'Test Description',
        categoryId: '1',
        stakeAmount: 100,
        createdById: mockWager.createdById,
      };

      const result = await service.createWager(createWagerDto);
      expect(prisma.wager.create).toHaveBeenCalledWith({
        data: createWagerDto,
      });
      expect(result).toEqual(mockWager);
    });
  });

  describe('getAllWagers', () => {
    it('should return wagers by status', async () => {
      const result = await service.getAllWagers(WagerStatus.PENDING);
      expect(prisma.wager.findMany).toHaveBeenCalledWith({
        where: { status: WagerStatus.PENDING },
      });
      expect(result).toEqual([mockWager]);
    });
  });

  describe('findOneById', () => {
    it('should return a wager by id', async () => {
      const result = await service.findOneById('1');
      expect(prisma.wager.findUnique).toHaveBeenCalledWith({
        where: { id: '1' },
      });
      expect(result).toEqual(mockWager);
    });
  });
});
