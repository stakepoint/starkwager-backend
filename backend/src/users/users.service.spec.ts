import { Test, TestingModule } from '@nestjs/testing';
import { UsersService } from './users.service';
import { PrismaService } from 'nestjs-prisma';
import { UpdateUsernameDto } from './dto/update-username.dto';
import { User } from '@prisma/client';

describe('UsersService', () => {
  let service: UsersService;
  let prismaService: PrismaService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [UsersService, PrismaService],
    }).compile();

    service = module.get<UsersService>(UsersService);
    prismaService = module.get<PrismaService>(PrismaService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
});

// import { Test, TestingModule } from '@nestjs/testing';
// import { UsersService } from './users.service';
// import { PrismaService } from '../prisma/prisma.service';
// import { User } from '@prisma/client';
// import { DeepMockProxy, mockDeep } from 'jest-mock-extended';

// describe('UserService', () => {
//   let userService: UsersService;
//   let prismaService: DeepMockProxy<PrismaService>;

//   beforeEach(async () => {
//     const module: TestingModule = await Test.createTestingModule({
//       providers: [
//         UsersService,
//         {
//           provide: PrismaService,
//           useValue: mockDeep<PrismaService>(),
//         },
//       ],
//     }).compile();

//     userService = module.get(UsersService);
//     prismaService = module.get(PrismaService);
//   });

//   // Create user test
//   it('should create a new user', async () => {
//     const userDto = {
//       email: 'test@example.com',
//       name: 'Test User',
//     };
//     const createdUser: User = {
//       id: 1,
//       ...userDto,
//     };

//     prismaService.user.create.mockResolvedValue(createdUser);

//     const result = await userService.create(userDto);

//     expect(prismaService.user.create).toHaveBeenCalledWith({
//       data: userDto,
//     });
//     expect(result).toEqual(createdUser);
//   });
// });

  describe('updateUsername', () => {
    it('should update the username', async () => {
      const userId = 'test-user-id';
      const updateUsernameDto: UpdateUsernameDto = { username: 'newUsername' };
      const updatedUser: User = {
        id: userId,
        address: 'test-address',
        email: 'test@example.com',
        username: 'newUsername',
        picture: null,
        isVerified: false,
        roles: 'User',
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      jest.spyOn(prismaService.user, 'update').mockResolvedValue(updatedUser);

      const result = await service.updateUsername(userId, updateUsernameDto);

      expect(result).toEqual(updatedUser);
      expect(prismaService.user.update).toHaveBeenCalledWith({
        where: { id: userId },
        data: { username: 'newUsername' },
      });
    });
  });
});
