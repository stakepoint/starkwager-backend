import { Test, TestingModule } from '@nestjs/testing';
import { UsersController } from './users.controller';
import { UsersService } from './users.service';
import { UpdateUsernameDto } from './dto/update-username.dto';
import { AuthGuard } from '../common/guards/auth.guard';
import { ExecutionContext } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';

describe('UsersController', () => {
  let controller: UsersController;
  let usersService: UsersService;

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      controllers: [UsersController],
      providers: [
        UsersService,
        {
          provide: AuthGuard,
          useValue: {
            canActivate: (context: ExecutionContext) => {
              const request = context.switchToHttp().getRequest();
              request.user = { id: 'test-user-id' };
              return true;
            },
          },
        },
        {
          provide: JwtService,
          useValue: {
            verifyAsync: jest.fn().mockResolvedValue({ id: 'test-user-id' }),
          },
        },
      ],
    }).compile();

    controller = module.get<UsersController>(UsersController);
    usersService = module.get<UsersService>(UsersService);
  });

  it('should be defined', () => {
    expect(controller).toBeDefined();
  });

  describe('updateUsername', () => {
    it('should update the username', async () => {
      const updateUsernameDto: UpdateUsernameDto = { username: 'newUsername' };
      const updatedUser = { id: 'test-user-id', username: 'newUsername' };

      jest.spyOn(usersService, 'updateUsername').mockResolvedValue(updatedUser);

      const result = await controller.updateUsername(
        { user: { id: 'test-user-id' } },
        updateUsernameDto,
      );

      expect(result).toEqual(updatedUser);
      expect(usersService.updateUsername).toHaveBeenCalledWith(
        'test-user-id',
        updateUsernameDto,
      );
    });
  });
});
