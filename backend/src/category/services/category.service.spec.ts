import { Test, TestingModule } from '@nestjs/testing';
import { CategoryService } from './category.service';
import { PrismaService } from 'nestjs-prisma';
import { CreateCategoryDto } from '../dtos/category.dto';
import { Category } from '@prisma/client';

describe('CategoryService', () => {
  let service: CategoryService;
  let prisma: PrismaService;

  const mockCategory: Category = {
    id: '1',
    name: 'Test Category',
    description: 'Test Description',
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CategoryService,
        {
          provide: PrismaService,
          useValue: {
            category: {
              create: jest.fn().mockResolvedValue(mockCategory),
              findMany: jest.fn().mockResolvedValue([mockCategory]),
              findUnique: jest.fn().mockResolvedValue(mockCategory),
              delete: jest.fn().mockResolvedValue(mockCategory),
            },
          },
        },
      ],
    }).compile();

    service = module.get<CategoryService>(CategoryService);
    prisma = module.get<PrismaService>(PrismaService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('create', () => {
    it('should create a category', async () => {
      const createCategoryDto: CreateCategoryDto = {
        name: 'Test Category',
        description: 'Test Description',
      };

      const result = await service.create(createCategoryDto);
      expect(prisma.category.create).toHaveBeenCalledWith({
        data: createCategoryDto,
      });
      expect(result).toEqual(mockCategory);
    });
  });

  describe('findAll', () => {
    it('should return all categories', async () => {
      const result = await service.findAll();
      expect(prisma.category.findMany).toHaveBeenCalled();
      expect(result).toEqual([mockCategory]);
    });
  });

  describe('findOne', () => {
    it('should return a category by id', async () => {
      const result = await service.findOne('1');
      expect(prisma.category.findUnique).toHaveBeenCalledWith({
        where: { id: '1' },
      });
      expect(result).toEqual(mockCategory);
    });
  });
});
