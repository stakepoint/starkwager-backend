// import { Test, TestingModule } from '@nestjs/testing';
// import { UsersService } from './users.service';

// describe('UsersService', () => {
//   let service: UsersService;

//   beforeEach(async () => {
//     const module: TestingModule = await Test.createTestingModule({
//       providers: [UsersService],
//     }).compile();

//     service = module.get<UsersService>(UsersService);
//   });

//   it('should be defined', () => {
//     expect(service).toBeDefined();
//   });
// });

import { Test, TestingModule } from '@nestjs/testing';
import { UsersService } from './users.service';
import { PrismaService } from '../prisma/prisma.service';
import { User } from '@prisma/client';
import { DeepMockProxy, mockDeep } from 'jest-mock-extended';

describe('UserService', () => {
  let userService: UsersService;
  let prismaService: DeepMockProxy<PrismaService>;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UsersService,
        {
          provide: PrismaService,
          useValue: mockDeep<PrismaService>(),
        },
      ],
    }).compile();

    userService = module.get(UsersService);
    prismaService = module.get(PrismaService);
  });

  // Create user test
  it('should create a new user', async () => {
    const userDto = {
      email: 'test@example.com',
      name: 'Test User',
    };
    const createdUser: User = {
      id: 1,
      ...userDto,
    };

    prismaService.user.create.mockResolvedValue(createdUser);

    const result = await userService.create(userDto);

    expect(prismaService.user.create).toHaveBeenCalledWith({
      data: userDto,
    });
    expect(result).toEqual(createdUser);
  });
});
