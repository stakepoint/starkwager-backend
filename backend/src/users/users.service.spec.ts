import { Test, TestingModule } from '@nestjs/testing';
import { User } from '@prisma/client';
import { PrismaService } from 'nestjs-prisma';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUsernameDto } from './dto/update-username.dto';
import { UsersService } from './users.service';

describe('UsersService', () => {
  let service: UsersService;
  let prisma: PrismaService;

  const mockUser: User = {
    id: '1',
    address: '0x123',
    email: 'test@example.com',
    username: 'testuser',
    createdAt: new Date(),
    updatedAt: new Date(),
    picture: '',
    isVerified: false,
    roles: 'User',
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UsersService,
        {
          provide: PrismaService,
          useValue: {
            user: {
              create: jest.fn().mockResolvedValue(mockUser),
              findMany: jest.fn().mockResolvedValue([mockUser]),
              findUnique: jest.fn().mockResolvedValue(mockUser),
              update: jest.fn().mockResolvedValue(mockUser),
            },
          },
        },
      ],
    }).compile();

    service = module.get<UsersService>(UsersService);
    prisma = module.get<PrismaService>(PrismaService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('create', () => {
    it('should create a user', async () => {
      const createUserDto: CreateUserDto = {
        address: '0x123',
        email: 'test@example.com',
        username: 'testuser',
      };

      const result = await service.create(createUserDto);
      expect(prisma.user.create).toHaveBeenCalledWith({
        data: createUserDto,
      });
      expect(result).toEqual(mockUser);
    });
  });

  describe('findAll', () => {
    it('should return all users when no pagination is provided', async () => {
      jest.spyOn(prisma.user, 'findMany').mockResolvedValue([mockUser]);
      jest.spyOn(prisma.user, 'count').mockResolvedValue(1);

      const result = await service.findAll();
      expect(prisma.user.findMany).toHaveBeenCalledWith({
        where: {},
      });
      expect(result).toEqual({
        data: [mockUser],
        total: 1,
      });
    });

    it('should return paginated users', async () => {
      jest.spyOn(prisma.user, 'findMany').mockResolvedValue([mockUser]);
      jest.spyOn(prisma.user, 'count').mockResolvedValue(1);

      const result = await service.findAll(1, 10);
      expect(prisma.user.findMany).toHaveBeenCalledWith({
        skip: 0,
        take: 10,
      });
      expect(result).toEqual({
        data: [mockUser],
        total: 1,
      });
    });

    it('should apply filters when provided', async () => {
      jest.spyOn(prisma.user, 'findMany').mockResolvedValue([mockUser]);
      jest.spyOn(prisma.user, 'count').mockResolvedValue(1);

      const filters = { email: 'test@example.com' };
      const result = await service.findAll(1, 10);

      expect(prisma.user.findMany).toHaveBeenCalledWith({
        where: filters,
        skip: 0,
        take: 10,
      });
      expect(result).toEqual({
        data: [mockUser],
        total: 1,
      });
    });
  });

  describe('findOne', () => {
    it('should return a user by id', async () => {
      const result = await service.findOne('1');
      expect(prisma.user.findUnique).toHaveBeenCalledWith({
        where: { id: '1' },
      });
      expect(result).toEqual(mockUser);
    });
    it('should return null if user is not found', async () => {
      jest.spyOn(prisma.user, 'findUnique').mockResolvedValue(null);

      const result = await service.findOne('999');
      expect(result).toBeNull();
    });
  });

  describe('findOneByAddress', () => {
    it('should return a user by address', async () => {
      const result = await service.findOneByAddress('0x123');
      expect(prisma.user.findUnique).toHaveBeenCalledWith({
        where: { address: '0x123' },
      });
      expect(result).toEqual(mockUser);
    });
  });

  describe('updateUsername', () => {
    it('should update a username', async () => {
      const updateUsernameDto: UpdateUsernameDto = {
        username: 'newusername',
      };

      const result = await service.updateUsername('1', updateUsernameDto);
      expect(prisma.user.update).toHaveBeenCalledWith({
        where: { id: '1' },
        data: { username: 'newusername' },
      });
      expect(result).toEqual(mockUser);
    });
    it('should throw an error if user is not found', async () => {
      jest
        .spyOn(prisma.user, 'update')
        .mockRejectedValue(new Error('User not found'));

      const updateUsernameDto: UpdateUsernameDto = {
        username: 'newusername',
      };

      await expect(
        service.updateUsername('999', updateUsernameDto),
      ).rejects.toThrow('User not found');
    });
  });

  describe('findOneByUsername', () => {
    it('should return a user by username', async () => {
      const result = await service.findOneByUsername('testuser');
      expect(prisma.user.findUnique).toHaveBeenCalledWith({
        where: { username: 'testuser' },
      });
      expect(result).toEqual(mockUser);
    });

    it('should return null if user is not found by username', async () => {
      jest.spyOn(prisma.user, 'findUnique').mockResolvedValue(null);

      const result = await service.findOneByUsername('nonexistentuser');
      expect(result).toBeNull();
    });
  });
});
