import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  Req,
  UseInterceptors,
} from '@nestjs/common';
import { ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { User } from '@prisma/client';
import { PaginationInterceptor } from 'src/common/decorators/pagination.decorator';
import { paginate } from 'src/common/utils/paginate';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateAvatarDto } from './dto/update-avatar.dto';
import { UpdateUsernameDto } from './dto/update-username.dto';
import { UsersService } from './users.service';

@ApiBearerAuth('JWT-AUTH')
@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Post('/create')
  create(@Body() createUserDto: CreateUserDto) {
    return this.usersService.create(createUserDto);
  }

  @Get()
  @UseInterceptors(PaginationInterceptor)
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  async findAll(@Query() query: User, @Req() request: Request) {
    const { page, limit } = request['pagination'];
    const filters = { ...query };

    const { data, total } = await this.usersService.findAll(
      page,
      limit,
      Object.keys(filters).length > 0 ? filters : undefined,
    );

    return paginate(data, total, page, limit);
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.usersService.findOne(id);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.usersService.remove(+id);
  }

  @Patch('/update')
  updateUsername(@Req() req, @Body() updateUsernameDto: UpdateUsernameDto) {
    const userId = req.user.sub;
    return this.usersService.updateUsername(userId, updateUsernameDto);
  }

  @Patch('/avatar')
  updateAvatar(@Req() req, @Body() updateAvatarDto: UpdateAvatarDto) {
    const userId = req.user.sub;
    return this.usersService.updateAvatar(userId, updateAvatarDto);
  }
}
