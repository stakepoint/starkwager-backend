import {
  Controller,
  Get,
  Post,
  Body,
  Patch,
  Param,
  Delete,
  Req,
} from '@nestjs/common';
import { UsersService } from './users.service';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUsernameDto } from './dto/update-username.dto';
import { ApiBearerAuth } from '@nestjs/swagger';
import { UpdateAvatarDto } from './dto/update-avatar.dto';

@ApiBearerAuth('JWT-AUTH')
@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Post('/create')
  create(@Body() createUserDto: CreateUserDto) {
    return this.usersService.create(createUserDto);
  }

  @Get()
  findAll() {
    return this.usersService.findAll();
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

  @Patch(':id/avatar')
  updateAvatar(@Param('id') id: string, @Body() updateAvatarDto: UpdateAvatarDto) {
    return this.usersService.updateUsername(id, null, updateAvatarDto);
  }
}
